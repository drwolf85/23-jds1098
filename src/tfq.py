import time
import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '1'
import tensorflow as tf
from ctypes import *
import numpy as np
import pandas as pd
import cirq
import sympy
import tensorflow_quantum as tfq

lib = cdll.LoadLibrary("./analysis.so")
lib.toBinFl32.restype = None
lib.toIndFl32.restype = None

# Loop over the counties
for county in [17105, 17113, 31135, 38075, 39149, 48189]:
    # Read the data
    filename = f"../dta/alldata_{county}.feather"
    rasterz = np.array(pd.read_feather(filename), dtype = "uint8", order = "C")
    rasterz, wgt = np.unique(rasterz, return_counts = True, axis = 0)
    twlen = rasterz.shape[1]
    bindata = np.zeros([rasterz.shape[0], rasterz.shape[1], 8], dtype="uint8")
    tic = time.time()
    for year in range(twlen):
        dta = rasterz[:,year] 
        lib.toBinFl32(bindata.ctypes, dta.ctypes, 
            c_size_t(dta.size), c_size_t(year), c_size_t(twlen))
    # print("Conversion time: {}".format(convTime))
    del(dta)
    # Preparing quantum data
    qubits = cirq.LineQubit.range(4) # Initialize the qubits
    operator_data = tfq.convert_to_tensor([cirq.Z(qubits[k]) 
        for k in range(4)] * bindata.shape[0]) 
    # Parameters that the classical NN will feed values into.
    control_params = sympy.symbols('theta{0:4}{0}')

    # Create the parameterized circuit.
    model_circuit = cirq.Circuit()
    for i in range(4):
        model_circuit.append(cirq.H(qubits[i]))
        model_circuit.append(cirq.ry(np.pi * control_params[i + 0]).on(qubits[i]))
    for i in range(1, 4):
        model_circuit.append(cirq.CNOT(qubits[i], qubits[i-1]))

    model_circuit.append(cirq.CNOT(qubits[0], qubits[3])) 
    dp_circ = tfq.convert_to_tensor([model_circuit] * bindata.shape[0]) # quantum data
    toc = time.time()
    convTime = toc - tic
    # print("Conversion time: {}".format(convTime))
    f = open(f"../res/tfq_results_{county}.txt", "w")
    f.write(f"Conversion time: {convTime}\n")
    f.close()

    for i in range(50):
        # Definition of the neural model
        circuits_input = tf.keras.Input(shape=(), dtype = tf.dtypes.string, name = 'circuit_input')
        operators_input = tf.keras.Input(shape=(1,), dtype = tf.dtypes.string, name = 'operators_input')
        full_circuit = tfq.layers.AddCircuit()(circuits_input, append = model_circuit)
        commands_input = tf.keras.layers.Input(shape = (bindata.shape[1] - 2, 8), dtype = tf.dtypes.float32, name = "commands_input")
        controller = tf.keras.Sequential([
            tf.keras.layers.SimpleRNN(256, input_shape = (bindata.shape[1] - 2, 8), 
                unroll = True, activation = "relu"),
            tf.keras.layers.Dropout(0.5),
            tf.keras.layers.Dense(units = 4, activation = "tanh")
        ])
        symbol_values = controller(commands_input)
        expectations = tfq.layers.Expectation()(full_circuit, symbol_names = control_params, symbol_values = symbol_values, operators = operators_input)
        output = tf.keras.Sequential([
            tf.keras.layers.Dense(units = 8, activation = "sigmoid")
        ])(expectations)
        net = tf.keras.Model(inputs=[circuits_input, commands_input, operators_input], outputs = [output])
        print(net.summary())
        mAdam = tf.keras.optimizers.Adam(learning_rate = 1e-4)
        net.compile(loss="binary_crossentropy", optimizer = mAdam, metrics = "binary_accuracy")
        tic = time.time()
        net.fit([dp_circ, bindata[:, 0:(twlen - 2), :], operator_data[0:bindata.shape[0]]], 
            bindata[:, twlen - 2,:], sample_weight = wgt/wgt.sum(),
            epochs = 128, batch_size = 64, shuffle = True)
        toc = time.time()
        # Measures of accuracy
        yhat = net.predict([dp_circ, bindata[:, 1:(twlen - 1), :], operator_data[0:bindata.shape[0]]], max_queue_size = 8192, use_multiprocessing = True)
        fctrs = np.reshape([1, 2, 4, 8, 16, 32, 64, 128], (8, 1))
        ytru = tf.matmul(np.array(bindata[:, twlen - 1, :], dtype="half"), fctrs)
        caha = np.array(yhat > 0.5, dtype="half")
        caha = tf.matmul(caha, fctrs)
        overall = (np.matmul(wgt, np.array(ytru == caha))/wgt.sum())[0]
        f = open(f"../res/tfq_results_{county}.txt", "a")
        f.write(f"Overall:{np.round(overall * 100, 8)}\n" +
                f"\nTraining time:{np.round(toc-tic, 3)}\n")
        f.close()
