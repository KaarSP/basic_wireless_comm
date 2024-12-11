% This program walks through for the basic understanding of a
% single-carrier communication system modulated with QAM scheme and
% filtered by pulse shaping filters. Channel is modelled by AWGN. The
% result is analysed using BER parameter. Also, the spectrum analyser is
% implemented to visullay understand the path
% 
% Tx      : Source Bits -> Modulator -> Transmit Filter/IFFT
% Channel : Multipath + AWGN
% Rx      : Receive Filter/FFT -> Demodulator -> Received Bits
%
% The performance parameter used is BER.       
% 
% There are 4 cases that are discussed here in this code
% 1. No Channel
% 2. AWGN Noise 
% 3. AWGN + Filters
% 4. Multipath
% Vary 'sym_param' to have a look at each case.
% Copyright MathWorks

%% 
clc;
clear;
close all;
%% TRANSMITTER

% Simulation Parameter
sym_param = 4; % 0: No Channel, 1: AWGN Noise, 2: AWGN + Filters, 3: Multipath

numBits       = 20000;           % Number of bits to be transmitted
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

if (sym_param == 2) || (sym_param == 3)
    % Transmit Filter - Pulse Shaping Filter
    % Root Raised Cosine filter
    txFilt = comm.RaisedCosineTransmitFilter;
    txFiltOut = txFilt(modOut);
    scatterplot(txFiltOut);
    title('Transmit Filtered Output');
end

%% CHANNEL
if sym_param == 1
    chanOut = awgn(modOut,SNR,'measured');
    scatterplot(chanOut);
    title('Channel Output');
elseif sym_param == 2
    chanOut = awgn(txFiltOut,SNR,'measured');
    scatterplot(chanOut);
    title('Channel Output');
elseif sym_param == 3
    % Multipath coefficients (Sum of impulse response)
    mpChan = [0.8 0 0 0 0 0 0 0 -0.5 0 0 0 0 0 0 0 0.34].'; % 17 multipaths
    % stem(mpChan);
    mpChanOut = filter(mpChan,1,txFiltOut);
    chanOut = awgn(mpChanOut,SNR,'measured');
    scatterplot(chanOut);
    title('Channel Output');
end
%% RECEIVER
if (sym_param == 2) || (sym_param == 3)
    % Receiver Filter - Pulse Shaping Filter
    % Root Raised Cosine filter
    rxFilt = comm.RaisedCosineReceiveFilter;
    rxFiltOut = rxFilt(chanOut);
    scatterplot(rxFiltOut);
    title('Receiver Filter Output');
end 

% Demodulation
if sym_param == 0
    demodOut = qamdemod(modOut,modOrder,'OutputType','bit','UnitAveragePower',true);
elseif sym_param == 1
    demodOut = qamdemod(chanOut,modOrder,'OutputType','bit','UnitAveragePower',true);
elseif (sym_param == 2) || (sym_param == 3)
    demodOut = qamdemod(rxFiltOut,modOrder,'OutputType','bit','UnitAveragePower',true);
end

%% Bit Error Rate
if (sym_param == 0) || (sym_param == 1)
    numBitErrors = nnz(srcBits ~= demodOut);
    numdemodBits = length(demodOut);
    ber = numBitErrors/numdemodBits;
    fprintf('BER is %3f%%\n', ber*100)
elseif (sym_param == 2) || (sym_param == 3)
    % Delay in symbols is half of the filter length
    delayInSymbols = (txFilt.FilterSpanInSymbols/2) + (rxFilt.FilterSpanInSymbols/2);
    delayInBits = delayInSymbols * bitsPerSymbol; % Delay in Bits 
    
    srcAligned = srcBits(1:end-delayInBits);
    
    
    demodAligned = demodOut((delayInBits+1):end);
    plot(srcBits); hold on;
    plot(demodOut);
    numBitErrors = nnz(srcAligned ~= demodAligned);
    
    numAlignedBits = length(srcAligned);
    
    ber = numBitErrors/numAlignedBits;
    fprintf('BER is %3f%%\n', ber*100)
end

% Spectrum Analyzer
if (sym_param == 2) || (sym_param == 3)
    scope = spectrumAnalyzer("NumInputPorts",2,"SpectralAverages",50, "ShowLegend",true);
    scope(txFiltOut,chanOut);
end