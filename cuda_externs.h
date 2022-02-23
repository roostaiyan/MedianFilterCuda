#ifndef CUDA_EXTERNS_H
#define CUDA_EXTERNS_H

#include <opencv2/core/cuda.hpp>

extern
void medianFilterCu(const cv::cuda::GpuMat &src,
                    cv::cuda::GpuMat &dst,
                    cv::cuda::Stream &stream);

#endif // CUDA_EXTERNS_H
