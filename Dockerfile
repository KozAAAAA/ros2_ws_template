ARG ROS_DISTRO=rolling-ros-base-noble
FROM ros:$ROS_DISTRO

ARG USERNAME
ARG WORKSPACE
ARG ROSDEP_SOURCE
ARG USER_UID
ARG USER_GID=$USER_UID

ARG PROJECT_PATH=/home/$USERNAME/$WORKSPACE

SHELL ["/bin/bash", "-c"]

# Create user
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
  && usermod -a -G video $USERNAME \
  && apt-get update \
  && apt-get install -y sudo \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME

RUN apt-get update && apt-get upgrade -y

# Only for development tools - do not put package dependencies here
RUN apt-get install -y --fix-missing --quiet --no-install-recommends \
  git \
  neovim \
  python3-pip

# Copy project files
COPY ./src $PROJECT_PATH/src
COPY ./launch $PROJECT_PATH/launch
COPY ./config $PROJECT_PATH/config
COPY ./rosdep $PROJECT_PATH/rosdep
WORKDIR $PROJECT_PATH

# Install ROS2 dependencies
ENV PIP_BREAK_SYSTEM_PACKAGES=1
RUN echo "yaml $ROSDEP_SOURCE" >> /etc/ros/rosdep/sources.list.d/20-default.list
RUN rosdep update
RUN rosdep install --from-paths src --ignore-src -r -y

# Build project
RUN source /opt/ros/$ROS_DISTRO/setup.bash && \
  colcon build --symlink-install

# Make sure the user has access to the project files
RUN chown -R $USERNAME:$USERNAME $PROJECT_PATH

RUN rm -rf /var/lib/apt/lists/*
USER $USERNAME
