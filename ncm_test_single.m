function direction = ncm_test_single(datapoint, par)
% 1 for left, 2 for right

    %mahalDistance = 1;    

    Pred_class = 0;
    Pred = 0;
    distance = zeros(size(par,1),1);
    for n = 1:length(par)
        %if mahalDistance
        %    distance(n) = mean(mahal(datapoint', par(n,1 : size(par,2)-1)')); 
        %else
            distance(n) = mean(dist2(datapoint, par(n,1 : size(par,2)-1)));
        %end
    end
    [minvalue, minidx] = min(distance);
    Pred_class = minidx;
    Pred = par(Pred_class, size(par,2));
        
    if Pred == 1
        direction = 1;
    elseif Pred == 0
        direction = 2;
    end
     
end