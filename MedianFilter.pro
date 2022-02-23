#-------------------------------------------------
# Project created by QtCreator
#-------------------------------------------------

CONFIG += console

TARGET = median_test

# cuda compile directory
DESTDIR = ./
CUDA_OBJECTS_DIR = OBJECTS_DIR/../cuda

# This makes the .cu files appear in your project
CUDA_SOURCES += \
    median.cu

HEADERS += \
    cuda_externs.h

SOURCES += \
    main.cpp


CUDA_DIR    = /usr/local/cuda         # Path to cuda toolkit install
OPENCV_DIR  = /usr/local/opencv4      # Path to opencv4 install

CONFIG +=link_pkgconfig PKGCONFIG+=opencv4

INCLUDEPATH += $$OPENCV_DIR/include/opencv4
LIBS += -L$$OPENCV_DIR/lib \
             -lopencv_core -lopencv_imgproc -lopencv_highgui  \
             -lopencv_tracking -lopencv_video -lopencv_calib3d -lopencv_photo -lopencv_ximgproc \
             -lopencv_cudawarping -lopencv_cudaimgproc -lopencv_cudafilters -lopencv_cudaarithm \
             -lopencv_imgcodecs -lopencv_features2d -lopencv_ml -lopencv_cudaobjdetect


CUDA_OBJECTS_DIR = OBJECTS_DIR/../cuda

# CUDA NVCC Compiler Settings
SYSTEM_NAME = linux                 # Depending on your system either 'Win32', 'x64', or 'Win64'
SYSTEM_TYPE = 64                    # '32' or '64', depending on your system
NVCC_OPTIONS = -use_fast_math
NVCC_GEN     = -gencode arch=compute_37,code=sm_37 -gencode arch=compute_50,code=sm_50 -gencode arch=compute_52,code=sm_52 -gencode arch=compute_60,code=sm_60 -gencode arch=compute_61,code=sm_61 -gencode arch=compute_70,code=sm_70 -gencode arch=compute_75,code=sm_75 -gencode arch=compute_80,code=sm_80

# include paths
INCLUDEPATH += $$CUDA_DIR/include \
               $$CUDA_DIR/samples/common/inc \
               $$OPENCV_DIR/include/opencv4

# library directories
LIBS        += -L$$CUDA_DIR/lib64 \
               -L$$CUDA_DIR/samples/common/lib/$$SYSTEM_NAME \
               -L$$CUDA_DIR/samples/common/lib/$$SYSTEM_NAME/stubs \
               -L$$OPENCV_DIR/lib

# The following makes sure all path names (which often include spaces) are put between quotation marks
NVCC_INC = $$join(INCLUDEPATH,'" -I"','-I"','"')

OPENCV_LIB_NAMES =  opencv_core     opencv_imgproc      opencv_highgui

CUDA_LIB_NAMES   =  cudart

ALL_LIB_NAMES = $$OPENCV_LIB_NAMES $$CUDA_LIB_NAMES
for(lib, ALL_LIB_NAMES) {
    ALL_LIBS += -l$$lib
}

LIBS += $$ALL_LIBS

SHARED_LIB_CUDA_FLAG = ""

equals(TEMPLATE, "lib"){
    SHARED_LIB_CUDA_FLAG = "-Xcompiler -fPIC sahred"
}

CONFIG(debug, debug|release) {
    # Debug mode
    nvcc_command.input  = CUDA_SOURCES
    nvcc_command.output = $$CUDA_OBJECTS_DIR/${QMAKE_FILE_BASE}_cuda.o
    nvcc_command.commands = $$CUDA_DIR/bin/nvcc -D_DEBUG $$NVCC_OPTIONS $$NVCC_INC $$LIBS \
                      --machine $$SYSTEM_TYPE $$NVCC_GEN -dc \
                      $$SHARED_LIB_CUDA_FLAG \
                      -o ${QMAKE_FILE_OUT} -c ${QMAKE_FILE_NAME}
    nvcc_command.variable_out = CUDA_OBJS
    nvcc_command.variable_out += OBJECTS
    nvcc_command.clean = $$CUDA_OBJECTS_DIR/*.o
    nvcc_command.dependency_type = TYPE_C
    QMAKE_EXTRA_COMPILERS += nvcc_command
}
else {
    # Release mode
    nvcc_command.input = CUDA_SOURCES
    nvcc_command.output = $$CUDA_OBJECTS_DIR/${QMAKE_FILE_BASE}_cuda.o
    nvcc_command.commands = $$CUDA_DIR/bin/nvcc $$NVCC_OPTIONS $$NVCC_INC $$LIBS \
                      --machine $$SYSTEM_TYPE $$NVCC_GEN -dc \
                      $$SHARED_LIB_CUDA_FLAG \
                      -o ${QMAKE_FILE_OUT} -c ${QMAKE_FILE_NAME}
    nvcc_command.variable_out = CUDA_OBJS
    nvcc_command.variable_out += OBJECTS
    nvcc_command.clean = $$CUDA_OBJECTS_DIR/*.o
    nvcc_command.dependency_type = TYPE_C
    QMAKE_EXTRA_COMPILERS += nvcc_command
}

CONFIG(debug, debug|release) {
    # Debug mode
    nvcc_linker.input = CUDA_OBJS
    nvcc_linker.output = $$CUDA_OBJECTS_DIR/${QMAKE_FILE_BASE}_link.o
    nvcc_linker.commands = $$CUDA_DIR/bin/nvcc -D_DEBUG $$LIBS \
                      --machine $$SYSTEM_TYPE $$NVCC_GEN -dlink \
                      -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME}
    nvcc_linker.dependency_type = TYPE_C
    QMAKE_EXTRA_COMPILERS += nvcc_linker
}
else {
    # Release mode
    nvcc_linker.input = CUDA_OBJS
    nvcc_linker.output = $$CUDA_OBJECTS_DIR/${QMAKE_FILE_BASE}_link.o
    nvcc_linker.commands = $$CUDA_DIR/bin/nvcc $$LIBS\
                      --machine $$SYSTEM_TYPE $$NVCC_GEN -dlink \
                      -o ${QMAKE_FILE_OUT} ${QMAKE_FILE_NAME}
    nvcc_linker.dependency_type = TYPE_C
    QMAKE_EXTRA_COMPILERS += nvcc_linker
}


