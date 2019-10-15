FROM ubuntu:18.04

RUN apt update && \
    apt-get install -y wget && \
    apt-get install -y gnupg2

# 1. Install CUDA Toolkit 10
RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/cuda-repo-ubuntu1804_10.1.243-1_amd64.deb
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
RUN dpkg -i cuda-repo-ubuntu1804_10.1.243-1_amd64.deb
RUN apt update
RUN apt install -y cuda

# 2. Install CuDNN 7 and NCCL 2
RUN wget https://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64/nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb
RUN dpkg -i nvidia-machine-learning-repo-ubuntu1804_1.0.0-1_amd64.deb && \
    apt install -y libcudnn7 libcudnn7-dev libnccl2 libc-ares-dev && \
    apt autoremove
# Link libraries to standard locations
RUN mkdir -p /usr/local/cuda-10.1/nccl/lib
RUN ln -s /usr/lib/x86_64-linux-gnu/libnccl.so.2 /usr/local/cuda/nccl/lib/
RUN ln -s /usr/lib/x86_64-linux-gnu/libcudnn.so.7 /usr/local/cuda-10.1/lib64/

RUN apt-get -y install build-essential cmake unzip pkg-config
RUN apt-get -y install libxmu-dev libxi-dev libglu1-mesa libglu1-mesa-dev
RUN apt-get -y install libjpeg-dev libpng-dev libtiff-dev
RUN apt-get -y install libavcodec-dev libavformat-dev libswscale-dev libv4l-dev
RUN apt-get -y install libxvidcore-dev libx264-dev
RUN apt-get -y install libgtk-3-dev
RUN apt-get -y install libopenblas-dev libatlas-base-dev liblapack-dev gfortran
RUN apt-get -y install libhdf5-serial-dev
RUN apt-get -y install python3-dev python3-tk python-imaging-tk
RUN apt-get -y install ffmpeg

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