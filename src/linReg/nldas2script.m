function [x] = nldas2script(degree, trials)

    if nargin < 1
        degree = 1;
    end
    
    if nargin < 2
        trials = 10;
    end

	load dinLinReg.txt;
	XA = dinLinReg;
    
    numTimesteps = 720;
    
    %Cut out so we're looking at data for just one cell
%     XA = XA(1:numTimesteps, :);
    
    totVars = size(XA,2) / 2;
    
    %Specify variables of interest
    xVars = 1:10;
    yVars = 1:10;
    
	X = XA(:, xVars);
    Y = XA(:,(totVars+1):end);
    
    stdY = std(Y);
    
    treavg = zeros(1, totVars);
    tseavg = zeros(1, totVars);
    
	for yVar = yVars
		y = Y(:, yVar);
		for trial = 1:trials
			[w(:, trial), Xpoly, terms, tre(trial), tse(trial)] = polyReg(X, y, degree, 0.1, true);
		end
		treavg(yVar) = mean(tre');
		tseavg(yVar) = mean(tse');
		wavg(:, yVar) = mean(w, 2);
	end
% 	save terms.txt terms -text;
% 	save results.txt wavg -ascii;

    tseavg = tseavg ./ stdY;
    tseavg;
    treavg = treavg ./ stdY;
    treavg

	x = 'Done!';
	
end