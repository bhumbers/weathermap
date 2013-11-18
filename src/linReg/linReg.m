% Computes the coefficient vector of a linear regression with n examples and m features per example
% @param X the matrix with the feature values of the examples of size n x m
% @param y the vector with the labels of the examples of size n
% @return w the vector with the regression coefficients of size m 
function [w] = linReg(X, y)
	w = ((y'*X)/(X'*X))';
	%w = pinv(X)*y;
end