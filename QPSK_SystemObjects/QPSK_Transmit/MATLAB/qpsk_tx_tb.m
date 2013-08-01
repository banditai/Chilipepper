%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% Initialization and Model/simulation parameters %%%%%%%%%%%%%%
OS_RATE = 8;
CORE_LATENCY = 4;
PAD_BITS = 24;
make_srrc_lut;
make_train_lut;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%% Emulate microprocessor packet creation %%%%%%%%%%%%%%%%%%%
% data payload creation
messageASCII = 'Hello World!';
message = double( unicode2native( messageASCII ) );
% add on length of message to the front with four bytes
msgLength = length( message );
messageWithNumBytes = [ mod( msgLength, 2^8 ),...
    mod( floor( msgLength/2^8 ), 2^8 ),...
    mod( floor( msgLength/2^16 ), 2^8 ), 1, message ];

ml = length( messageWithNumBytes );
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% FPGA radio transmit core%%%%%%%%%%%%%%%%%%%%%%%%%
data_in = 0;
numBytesFromFifo = 0;
% numsamp should be sum of header bits (89 bits total) plus message length
% times the symbol rate.
num_samp = ((ml+5)*CORE_LATENCY*OS_RATE)+(90*OS_RATE);
x = zeros( 1, num_samp );
counter = 0;  % to feed data at the correct rate (OS_RATE * SYMBOL_RATE)
for i1 = 1:(num_samp)
    if (i1 <= (89)*OS_RATE || numBytesFromFifo > ml-1)
        data_in = 0;
        HEADER_BITS = 1;
    else
        data_in = messageWithNumBytes( numBytesFromFifo + 1 );
        counter=counter+1;
        HEADER_BITS = 0;
    end
    if (counter == CORE_LATENCY*OS_RATE)
        numBytesFromFifo = numBytesFromFifo + 1;
        counter = 0;
    end
    [i_out,q_out] = qpsk_tx( uint8(data_in), i1, HEADER_BITS, ml);
    x_out = complex( i_out, q_out )/2^11;
    x( i1 ) = x_out;
end
index = find( abs( x )>sum( SRRC ));

offset = index( 1 ) + (PAD_BITS*OS_RATE) + (length( TB_i )*OS_RATE) + 6 + 11;
idx = offset:OS_RATE:index(end);

% seperate the channels
y = x( idx );
sc = zeros( 1, 2*length(y));
sc( 1:2:end ) = real( y );
sc( 2:2:end ) = imag( y );
sh = sign( sc );
sb = (sh + 1)/2;
d = zeros( 1, ceil(length(y)/4 ));
% convert the data to decimal numbers
for i1 = 1:length(y)/4
    si = sb( 1 + (i1 - 1)*OS_RATE:i1*OS_RATE );
    d( i1 ) = bi2de( round(si) );
end
% plot i and q channels and display the recovered messeage
figure( 1 )
clf
plot( real( x ), 'red' )
hold on
plot( imag( x ), 'green' )
title( 'Transmit samples' );
figure( 2 )
scatter(real(y),imag(y))
disp('Your Data Packet was');
d(3:end)
disp('Your message was');
disp(native2unicode(d(5:end-3)));

