% Computes the coefficient vector of a linear regression with n examples and m features per example.
% The examples are divided into two sets, one for training and one for testing.
% @param X the matrix with the feature values of the examples of size n x m
% @param y the vector with the labels of the examples of size n
% @param testPerc The percentage of examples to use to test. The complement is used as training data.
% Test examples are chosen randomly.
% @param addConstant (optional) Adds a constant coefficient to the linear regression
% @return w the vector with the regression coefficients of size m 
% @return trainError the root mean square error (RMSE) on the training set
% @return trainError the root mean square error (RMSE) on the test set
function [w, trainError, testError] = linRegTest(X, y, testPerc, addConstant)
    if nargin < 4
        addConstant = true;
    end


	if addConstant,
		X = [X, ones(size(X, 1), 1)];
	end
	n = size(X,1);
	m = size(X,2);
	trainSize = round((1 - testPerc)*n);
	order = rand(n,1);
	shuffled = sortrows([order,X,y]);
	XTrain = shuffled(1:trainSize, 2:(m + 1));
	yTrain = shuffled(1:trainSize, m + 2);
	XTest = shuffled((trainSize + 1):n, 2:(m + 1));
	yTest = shuffled((trainSize + 1):n, m + 2);
	w = linReg(XTrain, yTrain);
	yTrainPred = XTrain*w;
	yTestPred = XTest*w;
	trainError = sqrt(mean((yTrain - yTrainPred).^2));
	testError = sqrt(mean((yTest - yTestPred).^2));
end