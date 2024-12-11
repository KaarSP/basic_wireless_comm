% This program walks through for the basic understanding of a OFDM
% single-carrier communication system modulated with QAM scheme and
% filtered by pulse shaping filters. Channel is modelled by AWGN. The
% result is analysed using BER parameter. Also, the spectrum analyser is
% implemented to visullay understand the path.
% 
% Tx      : Source Bits -> Modulator -> IFFT -> Transmit Filter
% Channel : Multipath + AWGN
% Rx      : Receive Filter -> FFT -> Demodulator -> Received Bits
%
% The performance parameter used is BER.       
% 
% Copyright MathWorks

%% 
clc;
clear;
close all;
%% TRANSMITTER

numBits       = 32768;           % Number of bits to be transmitted
modOrder      = 16;              % Modulation order
bitsPerSymbol = log2(modOrder);  % modOrder = 2^bitsPerSymbol
SNR           = 15;              % Signal-to-Noise Ratio

% Random source bits
srcBits = randi([0,1],numBits,1);

% Modulation
modOut = qammod(srcBits,modOrder,'InputType','bit','UnitAveragePower',true);

% Modulated output
scatterplot(modOut);
title('Modulated Output');

ofdmModOut = ifft(modOut); % IFFT operation for OFDM

% Transmit Filter - Pulse Shaping Filter
% Root Raised Cosine filter
txFilt = comm.RaisedCosineTransmitFilter;
txFiltOut = txFilt(ofdmModOut);
scatterplot(txFiltOut);
title('Transmit Filtered Output');

%% CHANNEL
% Multipath coefficients (Sum of impulse response)
mpChan = [0.8 0 0 0 0 0 0 0 -0.5 0 0 0 0 0 0 0 0.34].'; % 17 multipaths
% stem(mpChan);
ofdmFiltOut = filter(mpChan,1,txFiltOut);
chanOut = awgn(ofdmFiltOut,SNR,'measured');
scatterplot(chanOut);
title('Channel Output');

%% RECEIVER
% Receiver Filter - Pulse Shaping Filter
% Root Raised Cosine filter
rxFilt = comm.RaisedCosineReceiveFilter;
rxFiltOut = rxFilt(chanOut);
scatterplot(rxFiltOut);
title('Receiver Filter Output');
ofdmDemodOut = fft(rxFiltOut);
scatterplot(ofdmDemodOut)
title("OFDM Demodulator Output") 

% Demodulation
demodOut = qamdemod(ofdmDemodOut,modOrder,'OutputType','bit','UnitAveragePower',true);


%% Bit Error Rate

% Delay in symbols is half of the filter length
delayInSymbols = (txFilt.FilterSpanInSymbols/2) + (rxFilt.FilterSpanInSymbols/2);
delayInBits = delayInSymbols * bitsPerSymbol; % Delay in Bits 

srcAligned = srcBits(1:end-delayInBits);

demodAligned = demodOut((delayInBits+1):end);

numBitErrors = nnz(srcBits ~= demodOut);

numAlignedBits = length(srcAligned);

ber = numBitErrors/numAlignedBits;
fprintf('BER is %3f%%\n', ber*100)


% Spectrum Analyzer
scope = spectrumAnalyzer("NumInputPorts",2,"SpectralAverages",50, "ShowLegend",true);
scope(txFiltOut,chanOut);
