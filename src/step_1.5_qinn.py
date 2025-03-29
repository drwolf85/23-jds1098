import time
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'
import tensorflow as tf
from ctypes import *
import numpy as np
import pandas as pd

lib = cdll.LoadLibrary("./analysis.so")
lib.toBinFl32.restype = None
lib.toIndFl32.restype = None

# Loop over the counties
for county in [17105, 17113, 31135, 38075, 39149, 48189]:
    # Read the data
    filename = f"../dta/alldata_{county}.feather"
    rasterz = np.array(pd.read_feather(filename), dtype = "uint8", order = "C")
    twlen = rasterz.shape[1]
    bindata = np.zeros([rasterz.shape[0], rasterz.shape[1], 8], dtype="uint8")
    tic = time.time()
    for year in range(twlen):
        dta = rasterz[:,year] 
        lib.toBinFl32(bindata.ctypes, dta.ctypes, 
            c_size_t(dta.size), c_size_t(year), c_size_t(twlen))
    toc = time.time()
    convTime = toc - tic
    # print("Conversion time: {}".format(convTime))
    f = open(f"../res/qinn_results_{county}.txt", "w")
    f.write(f"Conversion time: {convTime}\n")
    f.close()
    del(dta)
    for i in range(50):
        # Definition of the neural model
        net = tf.keras.Sequential([
            tf.keras.layers.SimpleRNN(9, input_shape = (twlen - 2, 8), unroll = True),
            tf.keras.layers.Dropout(0.5),
            tf.keras.layers.Dense(units = 64, activation = "relu"),
            tf.keras.layers.Dense(units = 8, activation = "sigmoid")
        ])
        print(net.summary())
        net.compile(loss="binary_crossentropy", optimizer = "adam", metrics = "binary_accuracy")
        tic = time.time()
        net.fit(bindata[:, 0:(twlen - 2), :], bindata[:, twlen - 2,:], 
            epochs = 4, batch_size = 2048, shuffle = True, validation_split = 0.2)
        toc = time.time()
        yhat = net.predict(bindata[:, 1:(twlen - 1), :], max_queue_size = 8192, use_multiprocessing = True)
        fctrs = np.reshape([1, 2, 4, 8, 16, 32, 64, 128], (8, 1))
        ytru = tf.matmul(np.array(bindata[:, twlen - 1, :], dtype="half"), fctrs)
        caha = np.array(yhat > 0.5, dtype="half")
        caha = tf.matmul(caha, fctrs)
        overall = np.mean(ytru == caha)
        f = open(f"../res/qinn_results_{county}.txt", "a")
        f.write(f"Overall:{np.round(overall * 100, 8)}" +
                f"\nTraining time:{np.round(toc-tic, 3)}\n")
        f.close()

