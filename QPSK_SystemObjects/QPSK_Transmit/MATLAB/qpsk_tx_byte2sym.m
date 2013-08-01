%#codegen
% this core runs at an oversampling rate of 8
function [d_out] = qpsk_tx_byte2sym(data_in, i1)

    OS_RATE = 8;
    tbi = TB_i;
    tbq = TB_q;

    persistent diLatch dqLatch
    persistent sentTrain
    persistent hModulator

    if (isempty(hModulator))
        hModulator = comm.QPSKModulator('BitInput',true, 'PhaseOffset', 5*pi/4);
    end
    
    if (isempty(sentTrain) || i1 == 1)
        diLatch = 0; dqLatch = 0;
        sentTrain = 0;
    end
    if (mod(i1,8) == 1)
        sentTrain = sentTrain + 1;
    end
    
    PAD_BITS = 24;
    if sentTrain <= 65+PAD_BITS                 % Overhead bits
        if mod(i1,8) == 1 && sentTrain <= PAD_BITS  % sending pad bits
            diLatch = mod(sentTrain,2);
            diLatch = diLatch*2-1;
            dqLatch = diLatch;
        elseif mod(i1,8) == 1                       % sending header bits
            diLatch = tbi(sentTrain-PAD_BITS);
            dqLatch = tbq(sentTrain-PAD_BITS);
        end
    else % sending data!
        if mod(i1,OS_RATE) == 1                 % Latency check
            d_out = step(hModulator, data_in == [true ; true]);
            diLatch = sign(real(d_out));
            dqLatch = sign(imag(d_out));
        end
    end
    d_out = complex(diLatch, dqLatch);          % output i and q bit
end
