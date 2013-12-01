function [ Pi ] = trainVAR( X, p)
%TRAINVAR Trains a VAR model for given meteorological data
%   X is an T x N vector, where N is the number of distinct variables per
%       timestep, T is the number of timesteps used for training.
%   p defines the lag order of the VAR model that will be trained
%   Note that the model will only be trained on elements (p+1...T); the
%   first (1 ... p) timesteps are used only as observational history for
%   the p+1'st element (the first used for a VAR equation).
%   OUTPUT: Pi is an (N*p + 1 x N) matrix specifying the trained VAR model:
%       X(t,:) = Pi(1,:) + sum_over_i=1:p(Pi((2+(i-1)*N):(2+(i+N)),:) * X(t-i,:)) + eps_t

% Reformulate as a SUR problem and do OLS for each variable
% See http://faculty.washington.edu/ezivot/econ584/notes/varModels.pdf

[T, N] = size(X);

%The t'th row of Z is comprised of the lagged observations for timestep t
% %Version w/ const offset
% k = N*p + 1;
% Z = zeros(T-p, k);
% Z(:,1) = 0; %constant offset term
% for t=1:T-p
%    Z(t,2:end) = reshape(flipud(X(t:t+p-1,:)), 1, N*p);
% end
%Version w/o const offset
k = N*p;
Z = zeros(T-p, k);
for t=1:T-p
   Z(t,:) = reshape(flipud(X(t:t+p-1,:)), 1, N*p);
end

%Now, we do OLS for each observation across all timesteps separately
Pi = zeros(k,N);
for i=1:N
   x_i = X(1+p:end,i); %time series of observations for variable i
   
   %System to be solved: x_i = Z*pi_i
   Pi(:,i) = Z \ x_i;
end

end

