function [x] = nldas2script(degree, trials)

	load dinLinReg.txt;
	XA = dinLinReg;
	X = XA(:, 1:10);
	for var = 1:10
		y = XA(:, (10 + var));
		for trial = 1:trials
			[w(:, trial), Xpoly, terms, tre(1, trial), tse(1, trial)] = polyReg(X, y, degree, 0.1, true);
		end
		treavg = mean(tre)
		tseavg = mean(tse)
		wavg(:, var) = mean(w, 2);
	end
% 	save terms.txt terms -text;
% 	save results.txt wavg -ascii;
	x = 'Done!';
	
end