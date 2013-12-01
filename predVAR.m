function [ Xt ] = predVAR( Pi, Xp, useConstOffset)
%TESTVAR Predicts X_t given [X_t-1, ... X_(t-p)];
%   Xp is a matrix of size (p' x N), where the i'th row gives the observed
%   values at time (t-p)+(i-1) (ie: Xp = [X_(t-p); X_(t-p+1); ... ; X_(t-1)])
%   Pi is a (k x N) matrix, where k = N*p (+ 1 if const offset used)
%   useConstOffset: If 1, a linear offset is included in the model
%   OUTPUT: Xt is a (1 x N) row vector giving the predicted value of the
%       observations at time t

    if nargin < 3
        useConstOffset = 0;
    end

    [k, N] = size(Pi);
    
    if (useConstOffset)
        p = (k-1)/N;
    else
        p = k/N;
    end
    
    %Note: I'm used to working w/ col vectors, so we use some transposes so
    %that we work in that space rather than w/ row vectors, then transpose
    %again to return out a row vector as the result
    

    if (useConstOffset)
        Xt = Pi(1,:)';
    else
        Xt = zeros(size(Xp,2),1);
    end
    
    rowOffset = 1;
    if (useConstOffset)
        rowOffset = 2;
    end
        
    %Add in contribution from each prior system state, from newest to oldest
    %Note the slightly funky ordering: Time offset increases by row for X
    %(which makes sense), but decreases by row for Pi, so we choose to index
    %"backwards" for the former.
    for i=1:p
        r1 = rowOffset + (i-1)*N;
        r2 = rowOffset + (i*N) - 1;
        pi =  Pi(r1:r2,:)'; %Extract coefficient matrix for this time step
        Xp_i = Xp(1+p-i,:)';
        Xt = Xt + (pi * Xp_i);
    end

    %Shift back
    Xt = Xt';
end


