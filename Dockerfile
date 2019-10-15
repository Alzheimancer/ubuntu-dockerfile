FROM ubuntu:18.04
LABEL maintainer "NVIDIA CORPORATION <cudatools@nvidia.com>"

RUN apt-get update && apt-get install -y --no-install-recommends \
gnupg2 curl ca-certificates && \
    curl -fsSL https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub | apt-key add - && \
    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list && \
    echo "deb https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/nvidia-ml.list && \
    apt-get purge --autoremove -y curl && \
rm -rf /var/lib/apt/lists/*

ENV CUDA_VERSION 10.1.243

ENV CUDA_PKG_VERSION 10-1=$CUDA_VERSION-1

# For libraries in the cuda-compat-* package: https://docs.nvidia.com/cuda/eula/index.html#attachment-a
RUN apt-get update && apt-get install -y --no-install-recommends \
        cuda-cudart-$CUDA_PKG_VERSION \
cuda-compat-10-1 && \
build-essential cmake unzip pkg-config && \
libxmu-dev libxi-dev libglu1-mesa libglu1-mesa-dev && \
libjpeg-dev libpng-dev libtiff-dev && \
libavcodec-dev libavformat-dev libswscale-dev libv4l-dev && \
libxvidcore-dev libx264-dev && \
libgtk-3-dev && \
libopenblas-dev libatlas-base-dev liblapack-dev gfortran && \
libhdf5-serial-dev && \
python3-dev python3-tk python-imaging-tk && \
ffmpeg && \
ln -s cuda-10.1 /usr/local/cuda && \
    rm -rf /var/lib/apt/lists/*

# Required for nvidia-docker v1
RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf

ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64

# nvidia-container-runtime
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=10.1 brand=tesla,driver>=384,driver<385 brand=tesla,driver>=396,driver<397 brand=tesla,driver>=410,driver<411"


RUN wget https://bootstrap.pypa.io/get-pip.py
RUN python3 get-pip.py

RUN pip install virtualenv virtualenvwrapper
RUN rm -rf ~/get-pip.py ~/.cache/pip

# virtualenv and virtualenvwrapper
RUN echo "export WORKON_HOME=$HOME/.virtualenvs" > .bashrc
RUN echo "export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3" > .bashrc
RUN source /usr/local/bin/virtualenvwrapper.sh

RUN source ~/.bashrc
RUN mkvirtualenv dl4cv -p python3
RUN workon dl4cv

# COPY requirements.txt ~/requirements.txt
RUN pip install numpy imutils eventlet Pillow 
RUN pip install requests progressbar2 h5py python-socketio scipy scikit-image scikit-learn

# Version to be installed
ENV OPENCV_VERSION=3.4.7

RUN wget -O opencv.zip https://github.com/opencv/opencv/archive/${OPENCV_VERSION}.zip
RUN wget -O opencv_contrib.zip https://github.com/opencv/opencv_contrib/archive/${OPENCV_VERSION}.zip

RUN unzip opencv.zip
RUN unzip opencv_contrib.zip

RUN mv opencv-${OPENCV_VERSION} opencv
RUN mv opencv_contrib-${OPENCV_VERSION} opencv_contrib

RUN cd ~/opencv
RUN mkdir build
RUN cd build
RUN cmake -D CMAKE_BUILD_TYPE=RELEASE \
	-D CMAKE_INSTALL_PREFIX=/usr/local \
	-D INSTALL_PYTHON_EXAMPLES=ON \
	-D INSTALL_C_EXAMPLES=OFF \
	-D OPENCV_EXTRA_MODULES_PATH=~/opencv_contrib/modules \
	-D PYTHON_EXECUTABLE=~/.virtualenvs/dl4cv/bin/python \
	-D OPENCV_ENABLE_NONFREE=ON \
	-D BUILD_EXAMPLES=ON ..

RUN make -j8
RUN make install
RUN ldconfig
RUN pkg-config --modversion opencv

RUN cd /usr/local/lib/python3.6/site-packages/cv2/python-3.6
RUN mv cv2.cpython-36m-x86_64-linux-gnu.so cv2.opencv${OPENCV_VERSION}.so
RUN cd ~/.virtualenvs/dl4cv/lib/python3.6/site-packages/
RUN ln -s /usr/local/lib/python3.6/site-packages/cv2/python-3.6/cv2.opencv3.4.7.so cv2.so
RUN echo "If everything worked fine, reboot now."