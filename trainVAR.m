function [ output_args ] = trainVAR( X, p)
%TRAINVAR Trains a VAR model for given meteorological data
%   X is an N x T vector, where N is the number of distinct variables per
%       timestep and T is the number of timesteps used for training
%   p defines the order of the VAR model that will be trained

% Reformulate as a SUR problem and do OLS for each variable
% See http://faculty.washington.edu/ezivot/econ584/notes/varModels.pdf

[n, T] = size(X);
k = n*p + 1;

Z = zeros(T, k);
Z(:,1) = 1; %constant offset term
for t=1:T
    
end


end

