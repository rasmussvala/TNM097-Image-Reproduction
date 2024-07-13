function [meanDeltaE, maxDeltaE] = meanAndMaxDeltaE(Lab_ref, Lab_test)

Lref = Lab_ref(:,1);
aref = Lab_ref(:,2);
bref = Lab_ref(:,3);

Ltest = Lab_test(:,1);
atest = Lab_test(:,2);
btest = Lab_test(:,3);

deltaE = sqrt((Ltest - Lref).^2 + (atest - aref).^2 + (btest - bref).^2);
maxDeltaE = max(max(deltaE));
meanDeltaE = mean(mean(deltaE));

end