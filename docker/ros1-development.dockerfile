FROM osrf/ros:noetic-desktop-full

# use bash instead of sh
SHELL ["/bin/bash", "-c"]
# accept the default answer for all questions
ENV DEBIAN_FRONTEND=noninteractive
# added by Alex, not sure how we use this
ENV CONAN_REVISIONS_ENABLED=1

# update system
RUN apt-get update && apt-get upgrade --yes

# get python deps 
RUN apt-get update && apt-get -y install python3 python3-pip
RUN pip install \
    conan \
    pyzbar \
    imutils 

# get ros deps and git
RUN apt-get update && apt-get -y install \
    ros-noetic-moveit \
    ros-noetic-moveit-kinematics \
    ros-noetic-xacro \
    ros-noetic-ros-controllers \
    ros-noetic-ros-control \
    ros-noetic-octomap \
    ros-noetic-octomap-mapping \
    libzbar0 \
    ros-noetic-rgbd-launch \
    ros-noetic-catkin \
    python3-catkin-tools \
    ros-noetic-trac-ik-kinematics-plugin \
    git \
    wget

# create workspace
RUN mkdir -p /catkin_ws/src
WORKDIR /catkin_ws
    
# compile packages
RUN catkin config --extend /opt/ros/$ROS_DISTRO \
    && catkin config --cmake-args -DCMAKE_BUILD_TYPE=Release \
    && catkin build

# add sourcing catkine_ws to entrypoint
RUN sed --in-place --expression \
    '$isource "/catkin_ws/devel/setup.bash"' \
    /ros_entrypoint.sh

# add packages to path
RUN echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> ~/.bashrc

# download moveit source after creating workspace
RUN apt-get update && \
	rosdep install --from-paths src --ignore-src -r -y && \
	rm -rf /var/lib/apt/lists/*
