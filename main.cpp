#include <iostream>
#include <chrono>
#include "cuda_externs.h"
#include <opencv2/imgcodecs.hpp>
#include <opencv2/highgui.hpp>

int main() {

    cv::Mat sample_im = cv::imread("./impnoise_005/12003.png", cv::IMREAD_UNCHANGED);
    cv::cuda::Stream stream;
    cv::cuda::GpuMat sample_im_gpu, median_im_gpu;
    sample_im_gpu.upload(sample_im, stream);
    stream.waitForCompletion();


    // first call usually takes more time due to kernel setup
    cv::cuda::createContinuous(sample_im_gpu.size(), sample_im_gpu.type(), median_im_gpu);
    medianFilterCu(sample_im_gpu, median_im_gpu, stream);
    stream.waitForCompletion();

    auto t = std::chrono::high_resolution_clock::now();
    medianFilterCu(sample_im_gpu, median_im_gpu, stream);
    stream.waitForCompletion();
    auto duration = (double) std::chrono::duration_cast<std::chrono::nanoseconds>(std::chrono::high_resolution_clock::now() - t).count() / 1000000;
    std::cout << " GPU TIME : " << duration << " milliseconds\n" << std::endl;

    cv::Mat medain_im;
    median_im_gpu.download(medain_im, stream);
    stream.waitForCompletion();

    namedWindow("InputImage", cv::WINDOW_NORMAL);
    cv::imshow("InputImage", sample_im);

    namedWindow("MedianResult", cv::WINDOW_NORMAL);
    cv::imshow("MedianResult", medain_im);
    cv::waitKey(0);

    return 0;
}
