# Supplementary materials of the paper entitled "*An Assessment of Crop-Specific Land Cover Predictions Using High-Order Markov Chains and Deep Neural Networks*"

The methodology of paper can be found at <https://doi.org/10.6339/23-JDS1098>.

## Hardware requirements

About 85GB of RAM are required to process the data files provided.

## Software requirements

The following programs are the minimal requirement to run/test the software provided:

* GNU C Compiler (GCC), version 4.9.3 or later.
* R, version 4.0.2 or later.
* GNU bash, version 4.4.19 or later.
* Python 3.8.10 or later.

The installation of required **python** and **R** packages is left to the user.

**NOTE**: the provided scripts are developed to be used in a generic Linux-based environment.

## Description of folders and files

* `README.md` is this file.

* `dta/` is the folder containing the datasets.

  * `dta/rasters/[COUNTY_FIPS]_mask.tif` is a raster mask file in GeoTIFF format. The county FIPS code `[COUNTY_FIPS]` is provided for six different counties, i.e.

    * Livingston County, IL (17105).
    * McLean County, IL (17113).
    * Perkins County, NE (31135).
    * Renville County, ND (38075).
    * Shelby County, OH (39149).
    * Hale County, TX (48189).

  * `dta/rasters/[COUNTY_FIPS]_mask.tfw` is an adjacent to the GeoTIFF.

* `res/` is the folder containing the results of the data analysis.

  * `res/[NET_ARCH]_results_[COUNTY_FIPS].txt` is the textual file containing the summary statistics produced for the counties with FIPS code `[COUNTY_FIPS]` using the Neural Network model `[NET_ARCH]`, i.e.

    * `dnn` is used for the DNN model in the manuscript.
    * `rnn_ii` is used for the RNN1 model in the manuscript.
    * `rnn_bi` is used for the RNN2 model in the manuscript.
    * `rnn_ib` is used for the RNN3 model in the manuscript.
    * `qinn` is used for the QINN model in the manuscript.

  * `res/homc_accuracy.txt` is the textual file containing the summary statistics produced using the Quantum-Inspired Neural Network (QINN) model.
  * `res/overall_means.csv` summarizes the overall accuracy results provided by the `.txt` files with the averages by county and neural network model.
  * `res/time_means.csv` summarizes the elapsed time (in seconds per epoch) provided by the `.txt` files with the averages by county and neural network model.

* `src/` is the folder containing the code to analyze the data.

  * `src/step_0.0_data_download.R` is the R script containing the code to download and prepare the raster datasets.
  * `src/step_0.1_data_prep.R` is the R script containing the code to convert the rasters files to feather datasets. This program needs the output of `src/step_0.0_data_download.R`.
  * `src/step_0.2_compress_data.py` is the python script containing the code to reduce the size of feather files. This program needs the output of `src/step_0.1_data_prep.R`.
  * `src/analysis.c` is the C file containing the code of the two functions used to convert the `uint8` raster data into indicator/dummy and binary variables.
  * `src/Makefile` is the file containing the instructions to compile the C code and create a shared-object (`.so`) library.
  * `src/step_1.0_homc.R` is the R script containing the code to execute the predictive analysis using the HOMC. This program needs the output of `src/step_0.2_compress_data.py`.
  * `src/step_1.1_dnn.py` is the python file containing the code to execute the predictive analysis using the DNN model. This program needs the output of `src/step_0.2_compress_data.py`.
  * `src/step_1.2_rnn_ii.py` is the python file containing the code to execute the predictive analysis using the RNN1. This program needs the output of `src/step_0.2_compress_data.py`.
  * `src/step_1.3_rnn_bi.py` is the python file containing the code to execute the predictive analysis using the RNN2. This program needs the output of `src/step_0.2_compress_data.py`.
  * `src/step_1.4_rnn_ib.py` is the python file containing the code to execute the predictive analysis using the RNN3. This program needs the output of `src/step_0.2_compress_data.py`.
  * `src/step_1.5_qinn.py` is the python file containing the code to execute the predictive analysis using the QINN. This program needs the output of `src/step_0.2_compress_data.py`.
  * `src/tfq.py` is the python file containing the code to execute the predictive analysis using the [tensorflow-quantum](https://www.tensorflow.org/quantum) layers in the model architecture. (Do not run if not enough memory is available.) This program needs the output of `src/step_0.2_compress_data.py`.
  * `src/step_2.0_analysis_ggplot2.R` is the R script containing the code to analyze the results and draw the boxplots. This program needs the output of `src/step_1.*.py`.

## Instruction for software usage

Once all the files are extracted as in their folders as described above, navigate to the `src` folder using the bash command:

```{bash}
cd src/
```

download the raster files and prepare the `feather` files using the following set of commands

```{bash}
Rscript step_0.0_data_download.R
Rscript step_0.1_data_prep.R
python3 step_0.2_compress_data.py
```

Compile the C code by entering the following command

```{bash}
make
```

Once the shared object `analysis.so` has been created, execute the analyses by running the python scripts as

```{bash}
for mycode in $(ls step_1.*.py); do python3 $mycode; done
```

For using high order Markov chain through an algorithm that bypasses the estimation of the transition probability matrix, the evaluation of the predictions can be obtained through:

```{bash}
Rscript step_1.0_homc.R
```

Once the predictive analyses are finalized, the distribution of the summary statistics can be obtained with the following command:

```{bash}
Rscript step_2.0_analysis_ggplot2.R
```

## Disclaimer

This repository is a scientific product and is not official communication of the National Agricultural Statistics Service, or the United States Department of Agriculture. All code is provided on an 'as is' basis and the user assumes responsibility for its use. THE AUTHORS DISCLAIM ALL LIABILITY FOR DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES RESULTING FROM YOUR MISUSE OF THE PROGRAMS. Any claims against the Department of Agriculture or the National Agricultural Statistics Service stemming from the use of this software will be governed by all applicable Federal law. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by the U.S. Department of Agriculture. The Department of Agriculture seal and logo, or the seal and logo of the National Agricultural Statistics Service, shall not be used in any manner to imply endorsement of any commercial product or activity by USDA or the United States Government.

The findings and conclusions derived from the use of this software should not be construed to represent any official USDA or US Government determination or policy. This software has been produced as part of a research project supported by the intramural research program of the US Department of Agriculture, National Agriculture Statistics Service.

## License

Software code created by U.S. Government employees is not subject to copyright in the United States (17 U.S.C. §105). The United States/Department of Agriculture reserve all rights to seek and obtain copyright protection in countries other than the United States for Software authored in its entirety by the Department of Agriculture. To this end, the Department of Agriculture hereby grants to Recipient a royalty-free, nonexclusive license to use, copy, and create derivative works of the Software outside of the United States.
