# A Dockerfile to install nvim and coc.nvim inside a Docker Image and then 
# import existing settings files to make my life easier.

# Change the base image according to the project
FROM ubuntu:latest

# Required to avoid installation stuck during the apt commands.
ENV DEBIAN_FRONTEND noninteractive

RUN apt update && \
    apt install -y --no-install-recommends \
        software-properties-common \
        htop \
        tmux \
    && \
    add-apt-repository ppa:neovim-ppa/unstable -y && \
    apt update && \
    apt install neovim -y && \
    curl -sL install-node.vercel.app/lts | bash -s -- -y && \
    apt purge vim -y && \
    rm -rf /var/lib/apt/lists/

# Since the Nvidia's image sets the WORKDIR as "/workspace"...
# Change temporarily the workspace directory to copy below files.
WORKDIR /

# The source directories can be relative or absolute path.
# BUT... 
# The source should be relative to the path that is executing the build command. 
# E.g. "COPY ../someDir" or "COPY ~/someUser" is not allowed if you haven't 
# included the directories previously.
COPY ./host_settings/init.vim root/.config/nvim/
COPY ./host_settings/coc-settings.json root/.config/nvim/
COPY ./host_settings/.tmux.conf root/

# Install coc.nvim based on the next link: 
# https://github.com/neoclide/coc.nvim/wiki/Install-coc.nvim#automation-script
RUN mkdir -p root/.local/share/nvim/site/pack/coc/start && \
    cd root/.local/share/nvim/site/pack/coc/start && \
    curl --fail -L https://github.com/neoclide/coc.nvim/archive/release.tar.gz | tar xzfv -

# For each mkdir step is required a new RUN command to save the directories.
RUN mkdir -p root/.config/coc/extensions && \
    cd root/.config/coc/extensions && \
    if [ ! -f package.json ]; then echo '{"dependencies":{}}'> package.json; fi && \
    npm install coc-pyright --global-style --ignore-scripts --no-bin-links --no-package-lock --only=prod

RUN echo "alias vim=\"nvim\"" >> root/.bashrc
RUN echo "source /root/.bashrc" >> root/.bash_profile

# Change back to the original workspace directory.
WORKDIR /workspace
