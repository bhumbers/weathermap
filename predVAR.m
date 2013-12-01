function [ Xt ] = predVAR( Pi, Xp)
%TESTVAR Predicts X_t given [X_t-1, ... X_(t-p)];
%   Xp is a matrix of size (p x N), where the i'th row gives the observed
%   values at time (t-p-1)+i (ie: Xp = [X_(t-p); X_(t-p+1); ... ; X_(t-1)])
%   Pi is a (k x N) matrix, where k = N*p + 1
%   OUTPUT: Xt is a (1 x N) row vector giving the predicted value of the
%       observations at time t

    [k, N] = size(Pi);
    p = (k-1)/N;
    
    %Note: I'm used to working w/ col vectors, so we use some transposes so
    %that we work in that space rather than w/ row vectors, then transpose
    %again to return out a row vector as the result
    
    %Version w/ const offset term
%     Xt = Pi(1,:)';
%     for i=1:p
%         r1 = 2 + (i-1)*N;
%         r2 = 2 + (i*N) - 1;
%         pi =  Pi(r1:r2,:)'; %Extract coefficient matrix for this time step
%         Xt = Xt + (pi * Xp(i,:)');
%     end 

    %Version w/o const offset term
    Xt = zeros(size(Xp,2),1);
    for i=1:p
        r1 = 1 + (i-1)*N;
        r2 = 1 + (i*N) - 1;
        pi = Pi(r1:r2,:)'; %Extract coefficient matrix for this time step
        Xt = Xt + (pi * Xp(i,:)');
    end 

    %Shift back
    Xt = Xt';
end


