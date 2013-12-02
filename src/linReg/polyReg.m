% Computes the coefficients vector of a polynomial regression with n examples and m features per example.
% The features are combined to create higher order features up to a provided degree.
% The examples are divided into two sets, one for training and one for testing.
% @param X the matrix with the feature values of the examples of size n x m
% @param y the vector with the labels of the examples of size n
% @param degree the maximum degree of the polynomial regression
% @param testPerc The percentage of examples to use to test. The complement is used as training data.
% Test examples are chosen randomly.
% @param addConstant (optional) Adds a constant coefficient to the regression
% @return w the vector with the regression coefficients of size m 
% @return Xpoly the feature matrix including all the higher polynomic terms
% @return trainError the root mean square error (RMSE) on the training set
% @return trainError the root mean square error (RMSE) on the test set
function [w, Xpoly, terms, trainError, testError] = polyReg(X, y, degree, testPerc, addConstant)
	
    if nargin < 5
        addConstant = true
    end

	% Determine regression terms
	m = size(X,2);
% 	basicTerms = [char(zeros(m, 1) .+ 'x'), strjust(num2str((1:m)'), 'left')];
	Xpoly = [];
	terms = [];
		indices = (0:m)';
		nTerms = unique(sort(npermutek(indices, degree), 2), 'rows');
		nTerms = nTerms(2:size(nTerms, 1), :);
		for i = 1:size(nTerms, 1)
			combination = nonzeros(nTerms(i, :));
			Xselect = X(:, sort(combination));
			Xpoly = [Xpoly, prod(Xselect, 2)];
			term = [];
			first = true;
			for j = 1:size(combination, 2)
				if first,
					times = '';
				else
					times = '*';
				end
% 				term = [term, times, basicTerms(combination(j), :)];
                term = [term, times];
				first = false;
			end
			terms = [terms; term];
		end
% 	if addConstant,
% 		terms = [terms; 'constant'];
% 	end
	
	% Compute regression
	[w, trainError, testError] = linRegTest(Xpoly, y, testPerc, addConstant);
end