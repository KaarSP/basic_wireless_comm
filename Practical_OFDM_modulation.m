% This program walks through for the basic understanding of a OFDM with
% Frequency Domain Equalization for a communication system modulated with 
% QAM scheme. Channel is modelled by AWGN. The result is analysed using 
% BER parameter.
% 
% Tx      : Source Bits -> Modulator -> OFDM Modulator
% Channel : Multipath + AWGN
% Rx      : OFDM Demodulator -> Equalizer -> Demodulator -> Received Bits
%
% The performance parameter used is BER.       
% 
% Copyright MathWorks

%% 
clc;
clear;
close all;
%% TRANSMITTER

modOrder        = 16;                   % for 16-QAM
bitsPerSymbol   = log2(modOrder);       % modOrder = 2^bitsPerSymbol
mpChan          = [0.8; zeros(7,1); -0.5; zeros(7,1); 0.34];  % multipath channel
SNR             = 15;                   % dB, signal-to-noise ratio of AWGN

numCarr = 8192;                         % Number of Sub-Carriers

numGBCarr = numCarr/16;                     % Guard Band
gbLeft = 1:numGBCarr;                       % Left Guard Band
gbRight = (numCarr-numGBCarr+1):numCarr;    % Right Guard Band

dcIdx = numCarr/2 + 1;
nullIdx = [gbLeft dcIdx gbRight]';

numDataCarr = numCarr - length(nullIdx);
numBits = numDataCarr*bitsPerSymbol;       % Number of bits to be transmitted      

% Random source bits
srcBits = randi([0,1],numBits,1);

% Modulation
qamModOut = qammod(srcBits,modOrder,"InputType","bit","UnitAveragePower",true);
scatterplot(qamModOut);
title('Modulated Output');

% Cyclic Prefix Length
cycPrefLen = 32; 

% OFDM Modulation
ofdmModOut = ofdmmod(qamModOut,numCarr,cycPrefLen,nullIdx);

%% CHANNEL

mpChanOut = filter(mpChan,1,ofdmModOut);
chanOut = awgn(mpChanOut,SNR,"measured");
scatterplot(chanOut);
title('Channel Output');

%% RECEIVER
% OFDM Demodulation
symOffset = 32;
ofdmDemodOut = ofdmdemod(chanOut,numCarr,cycPrefLen,symOffset,nullIdx);
scatterplot(ofdmDemodOut)
title("OFDM Demodulator Output") 

% FFT Shift
mpChanFreq = fftshift(fft(mpChan,numCarr));
mpChanFreq(nullIdx) = [];

% Equalization
eqOut = ofdmDemodOut ./ mpChanFreq;
scatterplot(eqOut);

% Demodulation
qamDemodOut = qamdemod(eqOut,modOrder,"OutputType","bit","UnitAveragePower",true);

%% Bit Error Rate
numBitErrors = nnz(srcBits~=qamDemodOut);
BER = numBitErrors/numBits;
fprintf('BER is %3f%%\n', BER*100);

%% Spectrum Analyzer
scope = spectrumAnalyzer("NumInputPorts",2,"SpectralAverages",50, "ShowLegend",true);
scope(ofdmModOut,chanOut);