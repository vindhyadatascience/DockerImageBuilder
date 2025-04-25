# DockerImageBuilder

The DockerImageBuilder is a powerful, layered approach to building complex Docker images that's ideal for computational research teams. The system breaks down the build process into discrete stages using configuration files and bash scripts, providing several key advantages:

* Efficient caching between builds
* Easy debugging at each stage
* Modular component assembly
* In-container source code compilation
* External code mounting support to reduce image size

The entire build process is captured in version-controlled configuration files, making it straightforward to reconstruct and update images as requirements evolve.

## Build a basic image

1. Clone this repository & move into the directory:

  ```bash
    git clone https://github.com/TBIO-RR-Group/DockerImageBuilder.git
    cd DockerImageBuilder
  ```

2. Set up the appropriate environment. You may use your choice of package/environment manager. Here we will show how to create the appropriate environment using mamba.

  ```bash
     mamba env create -f environment.yml
     mamba activate DockerImageBuilder
  ```

3. Create the image builder script. 
 
  ```bash
     bash generate_build.sh
  ```

4. Build the image. Must use sudo privileges to create appropriate base directories. This process takes approximately an hour depending on your system.

  ```bash
     sudo bash go_build.sh
  ```

5. Sync appropriate files to image.

  ```bash
    sudo build_self_contained_image.sh
  ```

## Recommendations for building a custom image.

* The default image has the following specifications:
  * base image - Ubuntu 22.04
  * python v3.10.6
  * R v4.4.2
  * IDEs - RStudio, Jupyter, JupyterLab, Visual Studio Code

* The user can change the base image of the build by editing the value assigned to `current_image` in `build_scripts/generate_master_build_script.sh`.
* The user can set which python version is used by editing `PYTHON_VERSION` in `config_files/setup.sh`. This image has been tested with v2.7.18, v3.8.12, v3.9.10, or v3.10.2. It is also possible to install multiple versions of Python.
* The user may need to specify the python3 path in `build_self_contained_image.sh`, depending on their setup.
* To update the R version, the user needs to update `R_version` in `setup.sh`.
* To change the R packages installed in the image, the user should edit `config_files/R_packages/rpkgs.txt`.
* The user can add their software of choice by adding a new step in `build_scripts/generate_master_build_script.sh`.
* The user can update the variables in `setup.sh` & `build_setup.sh` to change other parameters of the build.
* The user can control which steps in the build run (or don't run) by editing `build_scripts/generate_master_build_script.sh`.
* Some scripts exist in the repo but are unused to show how different software/packages could potentially be installed. These can be found in `build_scripts/efs` with the prefix BUILD_*.

## Dependencies

* Docker
* python3
