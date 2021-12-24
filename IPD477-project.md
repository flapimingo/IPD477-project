# Disclaimer
This repository was meant to be a fork of the original work available [here](https://gitlab.inria.fr/sb/simbci/-/tree/master). However, do to gitlab limitations, it's a copy of the repository with an added file to the project implementation.
This file can be found on the following route:
```
src/classifyTest_ssvep_proy.m
```


## IPD477 Project
### Poor performance in SSVEP BCI: Can simulations help with trials length definition?

This project implements the experiment presented on [Poor performance in SSVEP BCIs: are worse subjects just slower?](https://pubmed.ncbi.nlm.nih.gov/23366764/) using the simBCI framework.


### Simulator Implementation
This steps were followed to generate the present repository

#### Requisites
it's necessary to have installed the following toolboxs:
* Signal Processing Toolbox
* Image Processing Toolbox
* Statistics and Machine Learning Toolbox

#### Steps

* Download the files from the provided link on the [repository](http://openvibe.inria.fr/pub/src/simbci/)
* Unpack the compressed folders
* Copy the provided `leadfield*.mat` files into the 
`models` folder.
* Run the following command on matlab console to verify if the framework works correctly
```matlab
clear all; cd src; setup_paths
classifytest
```