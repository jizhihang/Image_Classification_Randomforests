% demo_tk2 demonstrates ULS or IGT random forest
% and compare error of Incremental Learning method with that of baseline
% This mfile consists of
%(1) generate (initial and incremental)train and test data using makespiral.m
%(2) obtain trees using rt1.m and initial training data
%(3) update trees using incremental training data
%(4) classify test data
%(6) execute Baseline method (use all training data to generate tree)
%(7) compare error of Incremental with that ofBaseline

%% chose incremental method (ULS, IGT)
method = 'ULS';
save method method;

%% (1)generate training and test data
clear
makespiral % save (i) training data in data.mat and (ii)clmax, mmax, nmax, depthmax in config.mat
% default values are following
% clmax=10;
% nmax=100;
% depthmax=20;
% mmax = 10;

% devide data into test and training data
datasize = size(data,1);
data_tr = data(1:round(0.7*datasize),:); % training data
data_ts = data(size(data_tr,1)+1:end,:); % test data
save('data_tr.mat','data_tr'); % this training data is not used for incremental learning, but for baseline
save('data_ts.mat','data_ts')

% divide training data into initial training data and incremental training data
% cl_init = 9; %% initial train data contain ind_init classes
cl_init = round(1.0*clmax); %% initial train data contain cl_init classes
ind_init = find(ismember(data(:,end), 1:cl_init)); %index of data,whose class are 1: cl_init
data_init = data(ind_init,:);
if cl_init == clmax;
    ind_inc = [];
else
    ind_inc = find(ismember(data(:,end), min(clmax,cl_init+1):clmax)); % incremental train data contain 3 classes
end
data_inc = data(ind_inc,:);
save('data_init.mat','data_init')
save('data_inc.mat','data_inc')

%% (2)generate initial trees using initial training data
clear 
load data_init
data = data_init; %initial training data

load config
% clmax = clmax -1; %initial training data don't contain class-clmax-data
clmax = max(unique(data(:,3)));
% nmax is not used;
% depthmax;
% mmax;

datasize=size(data,1);
for m=1:mmax
    % 1. sample test set Q
    Qx=randperm(datasize);
    Qx=Qx(1:round(datasize*0.7));

    % compute entropy the root node
    PQ=hist(data(Qx,3),1:clmax)+1e-6;
    PQ=PQ/sum(PQ);
    entropyQ=-1*sum(PQ.*log2(PQ));
    magnitudeQ=length(Qx);

    root=branch(Qx,0,magnitudeQ,entropyQ,PQ);
    root=grow(root,data,depthmax,clmax);

    save(strcat('tree',sprintf('%02d.mat',m)),'root');
end

%% (3) incremental learning with incremental training data
clear
load data_init %initial training data
load data_inc  %incremental training data
load method
load config
% clmax
% nmax is not used;
% depthmax;
% mmax;

data = [data_init; data_inc];
init_size = size(data_init,1);
inc_size = size(data_inc, 1);
for m=1:mmax
    % 1. sample test set Q
    Qx=randperm(inc_size);
%     Qx=Qx(1:round(inc_size*0.7)) + init_size;
    Qx = Qx(1:round(inc_size*0.7)) + init_size*ones(1,round(inc_size*0.7));

    load(strcat('tree',sprintf('%02d.mat',m)));

    % compute entropy the root node
    root.Qx = [root.Qx, Qx];
    root.magnitude = length(root.Qx);
    [root.PQ, root.entropy] = entropy(data, root.Qx, clmax);
    switch method
        case 'ULS'
            root = ULS(root, data, clmax);
        case 'ULS_tmp'
            root = ULS_tmp(root, data, Qx, clmax);
        case 'IGT'
            root = IGT(root, data, Qx, clmax, depthmax);
    end

    save(strcat('tree',sprintf('%02d.mat',m)),'root');
end

%% (4)classifiy test data
clear
load data_ts.mat % test data
data = data_ts;
save('data.mat','data'); % overwrite data because test loads data.mat

%calculate PQ_out; probability distribution of each data
test
[~,cpred] = max(PQ_out,[],2); % final predicted class
save cpred_IL cpred % save predected class

% %% (5)calculate error
% cmp = [cpred data(:,3)]; %1st collumn:predicted class, 2nd collumn; true class
% % error: the ratio of the number of misclassified data to the number of data
% error = sum(cmp(:,1) ~= cmp(:,2)) / size(data,1);

%% (6)baseline method
%% (6-1)generate decision tree using all training data (initial and incremental)
clear
% load training data and rename it as data
load data_tr.mat
data = data_tr;
save('data.mat','data'); %overwrite data

rt1 % use data.m and config.mat to generate and save root in tree01, tree02, etc.

%% (6-2)classify test data
clear
% load test data and rename it as data
load data_ts.mat
data = data_ts;
save('data.mat','data'); %overwrite data

%calculate PQ_out; probability distribution of each data 
test
[~,cpred] = max(PQ_out,[],2); % final predicted class
save cpred_BL cpred %save predected class

%% (7)error comparison
load data_ts
data = data_ts;
load cpred_BL
cpred_BL = cpred; %baseline
load cpred_IL
cpred_IL = cpred; %incremental learning
% error: the ratio of the number of misclassified data to the number of data
error_BL = sum(cpred_BL ~= data(:,3)) / size(data,1);
error_IL = sum(cpred_IL ~= data(:,3)) / size(data,1); % sometimes error is zero

cmp = [cpred_BL cpred_IL data(:,3)]; %for visualization

