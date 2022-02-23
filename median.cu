#include <opencv2/core/cuda.hpp>
#include <opencv2/core/cuda_stream_accessor.hpp>
#include <cuda_runtime.h>

#define WORKING_TYPE uchar
#define N_CHANNELS   1

constexpr int BLOCK_DIM_2D = 32;
constexpr int MEDIAN_WIN_SIZE = 5;
constexpr int MEDIAN_HALF_WIN_SIZE  = (MEDIAN_WIN_SIZE-1)/2;
constexpr int BLOCK_DIM_COMPUTE = BLOCK_DIM_2D-MEDIAN_HALF_WIN_SIZE;
constexpr int BLOCK_STEP = BLOCK_DIM_2D-2*MEDIAN_HALF_WIN_SIZE;

constexpr int MEDIAN_WIN_LEN = MEDIAN_WIN_SIZE*MEDIAN_WIN_SIZE;
__global__ void medianFilterKernel(const cv::cuda::PtrStepSz<WORKING_TYPE[N_CHANNELS]> input,
                                   cv::cuda::PtrStepSz<WORKING_TYPE[N_CHANNELS]> output,
                                   const int rows, const int cols)
{
    const int local_idx_y = threadIdx.y;
    const int local_idx_x = threadIdx.x;
    int row = blockIdx.y * BLOCK_STEP + local_idx_y - MEDIAN_HALF_WIN_SIZE;
    int col = blockIdx.x * BLOCK_STEP + local_idx_x - MEDIAN_HALF_WIN_SIZE;
    const int k = blockIdx.z * blockDim.z + threadIdx.z;
    if(k>=N_CHANNELS)
        return;
    __shared__ WORKING_TYPE sharedmem[BLOCK_DIM_2D][BLOCK_DIM_2D];  //initialize shared memory
    // take image values
    bool on_image = row>=0 && row<rows && col>=0 && col<cols;
    if(on_image)
        sharedmem[local_idx_y][local_idx_x] = input(row, col)[k];
     else
        sharedmem[local_idx_y][local_idx_x] = 0;
    __syncthreads();   // wait for all threads to be finished.

    if(!on_image)
        return;
    // check for borders
    if(local_idx_y<MEDIAN_HALF_WIN_SIZE || local_idx_x<MEDIAN_HALF_WIN_SIZE)
        return;
    if(local_idx_y>=BLOCK_DIM_COMPUTE || local_idx_x>=BLOCK_DIM_COMPUTE)
        return;
    // pick neighbors
    float vals[MEDIAN_WIN_LEN];
    for(int win_r = -MEDIAN_HALF_WIN_SIZE; win_r<=MEDIAN_HALF_WIN_SIZE; win_r++)
        for(int win_c = -MEDIAN_HALF_WIN_SIZE; win_c<=MEDIAN_HALF_WIN_SIZE; win_c++)
            vals[(MEDIAN_HALF_WIN_SIZE+win_r)*MEDIAN_WIN_SIZE+win_c+MEDIAN_HALF_WIN_SIZE] = sharedmem[local_idx_y+win_r][local_idx_x+win_c];

    // sorting
    for (int i = 0; i < MEDIAN_WIN_LEN; i++) {
        for (int j = i + 1; j < MEDIAN_WIN_LEN; j++) {
            if (vals[i] > vals[j]) {
                // swap
                float tmp = vals[i];
                vals[i] = vals[j];
                vals[j] = tmp;
            }
        }
    }

    output(row, col)[k] = vals[MEDIAN_WIN_LEN/2];   //Set the output image values.
}

extern
void medianFilterCu(const cv::cuda::GpuMat &src,
                    cv::cuda::GpuMat &dst,
                    cv::cuda::Stream &stream){

    cudaStream_t c_stream = cv::cuda::StreamAccessor::getStream(stream);
    size_t n_layers = src.channels();
    assert(n_layers==N_CHANNELS);

    int rows = src.rows;
    int cols = src.cols;

    cv::cuda::createContinuous(src.size(), src.type(), dst);

    //take block and grids.
     dim3 dimBlock(BLOCK_DIM_2D, BLOCK_DIM_2D, 1);
     dim3 dimGrid((int)ceil(((float)cols+BLOCK_STEP) / (float)BLOCK_STEP),
                  (int)ceil(((float)rows+BLOCK_STEP) / (float)BLOCK_STEP),
                  static_cast<int>(std::ceil(N_CHANNELS / static_cast<double>(dimBlock.z))));

    medianFilterKernel<<<dimGrid, dimBlock, 0, c_stream>>>(src, dst, rows, cols);

}
