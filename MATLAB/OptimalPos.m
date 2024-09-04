clear
clc
close all

%% Constraints
C = 10;
lamp = linspace(1.1,2,C);
lamn = linspace(0.1,0.9,C);
a = 1;
b = 1;
c = 0.5;
gam = 1;
Phi_u = zeros(C,1);
for i=1:C
    Phi_u(i) = Phiup(a,c,gam,lamp(i));
end
Phi_l = Phitil(b,c,lamn);
eps = 0.01;

% Rebate
theta = 1;
alpha = 1.2;
beta = 0.25;

%% BCGMY
params = [0.04,13/52,1.2,2/52,0,0,0.02,10/52,1.5,5/52,0,0];
M = 1/params(1);
G = 1/params(3);
cp = params(2);
cn = params(4);
yp = params(5);
yn = params(6);

% Discretization
N = 10000;
X = [-0.5,0.5];
x = linspace(X(1),X(2),N);
x2 = x.*x;

% alpha2-rebate
A_pa2 = cp*M.^(2*alpha+yp).*gamma(2*alpha-yp);
p_pa2 = (cp/A_pa2).*(x.^(2*alpha-yp-1)).*exp(-M*x).*(x>0);
A_na2 = cn*G.^(2*alpha+yn).*gamma(2*alpha-yn);
p_na2 = (cn/A_na2).*((-x).^(2*alpha-yn-1)).*exp(G*x).*(x<0);

% inner2
A_p2 = cp*M.^(2+yp).*gamma(2-yp);
p_p2 = (cp/A_p2).*(x.^(2-yp-1)).*exp(-M*x).*(x>0);
A_n2 = cn*G.^(2+yn).*gamma(2-yn);
p_n2 = (cn/A_n2).*((-x).^(2-yn-1)).*exp(G*x).*(x<0);

% inner4
A_p4 = cp*M.^(4+yp).*gamma(4-yp);
p_p4 = (cp/A_p4).*(x.^(4-yp-1)).*exp(-M*x).*(x>0);
A_n4 = cn*G.^(4+yn).*gamma(4-yn);
p_n4 = (cn/A_n4).*((-x).^(4-yn-1)).*exp(G*x).*(x<0);

% constraints
if yp>0
    B_p = (cp*M^(yp)) * ( (exp(-eps)*(eps^(-yp))/yp) - (1/yp)*igamma(yp,eps) );
else
    B_p = expint(eps);
end
p_p0 = (cp/B_p)*(exp(-M*x)./(x.^(1+yp))).*(x>eps);
if yn>0
    B_n = (cp*G^(yn)) * ( (exp(-eps)*(eps^(-yn))/yn) - (1/yn)*igamma(yn,eps) );
else
    B_n = expint(eps);
end
p_n0 = (cn/B_n)*(exp(G*x)./((-x).^(1+yn))).*(x<-eps);

%% Interpolation matrix
K = 50;
xx = linspace(x(1),x(end),K);
I = eye(K);
M = zeros(N,K);
for j=1:K
    ej = I(:,j);
    M(:,j) = interp1(xx,ej,x,'spline','extrap');
end


%% Optimization

% load python.exe

pyenv('Version',...
    'C:\Users\yoshi\OneDrive\Desktop\Research\OptimalDerivativePos\Maximin\maximin2\python.exe',...
    'ExecutionMode','OutOfProcess');
py.importlib.import_module('numpy');

p_pa2 = py.numpy.array(p_pa2.');
p_na2 = py.numpy.array(p_na2.');
p_p2 = py.numpy.array(p_p2.');
p_n2 = py.numpy.array(p_n2.');
p_p4 = py.numpy.array(p_p4.');
p_n4 = py.numpy.array(p_n4.');
A_pa2 = py.numpy.array(A_pa2.');
A_na2 = py.numpy.array(A_na2.');
A_p2 = py.numpy.array(A_p2.');
A_n2 = py.numpy.array(A_n2.');
A_p4 = py.numpy.array(A_p4.');
A_n4 = py.numpy.array(A_n4.');
B_p = py.numpy.array(B_p.');
p_p0 = py.numpy.array(p_p0.');
B_n = py.numpy.array(B_n.');
p_n0 = py.numpy.array(p_n0.');
M = py.numpy.array(M.');
lamp = py.numpy.array(lamp.');
lamn = py.numpy.array(lamn.');
Phi_u = py.numpy.array(Phi_u.');
Phi_l = py.numpy.array(Phi_l.');
x2 = py.numpy.array(x2.');

res = pyrunfile("OptimalPos_fun.py","z",...
    p_pa2 = p_pa2,...
    p_na2 = p_na2,...
    p_p2 = p_p2,...
    p_n2 = p_n2,...
    p_p4 = p_p2,...
    p_n4 = p_n4,...
    A_pa2 = A_pa2,...
    A_na2 = A_na2,...
    A_p2 = A_p2,...
    A_n2 = A_n2,...
    A_p4 = A_p4,...
    A_n4 = A_n4,...
    B_p = B_p,...
    p_p0 = p_p0,...
    B_n = B_n,...
    p_n0 = p_n0,...
    M = M,...
    lamp = lamp,...
    lamn= lamn,...
    Phi_u = Phi_u,...
    Phi_l = Phi_l,...
    x2 = x2,...
    N = N,...
    K = K,...
    C = C,...
    theta = theta,...
    alpha = alpha);

res = A*transpose(double(res));

%% Visualization

% % Optimal position
% figure()
% X = [-0.3,0.3];
% xlim = ([log(W)+X(1), log(W)+X(2)]);
% plot(x,res)
% fpath=('C:\Users\yoshi\OneDrive\Desktop\Research\OptimalDerivativePos\Figures');
% str=strcat('OptimalSolution_SPY');
% fname=str;
% saveas(gcf, fullfile(fpath, fname), 'epsc');

% Constraints
% zz = z.value
% N = len(a)
% const = []
% for i in range(N): #range(len(a)):
%     const.append(p @ np.maximum(zz-a[i],0))
% 
% const = np.array(const)
% fig = plt.figure()
% axes = fig.add_axes([0.1, 0.1, 0.75, 0.75])
% axes.set_xlim(a[0], a[-1])
% axes.set_ylim(min(const), max(Phi))
% axes.plot(a,const)
% axes.plot(a,Phi)
% # axes.plot(a,dist.Psi(a))
% plt.show()


%% Routines

function phi = Phitil(b,c,lam)
    phi = -(1-lam).*(log((1-lam)/b)/c)-(b/c)*(1 - (1-lam)/b );
end

function phi = Phiup(a,c,gam,lam)
    L = (lam-1)*(1+gam)/(a*c);
    f = @(u)( ( u / ( (1-u).^(gam/(1+gam)) ) - L )^2 );
    if lam < 1
        phi = 0;
    elseif lam == 1
        phi = a;
    elseif lam>1
        options = optimoptions('fmincon','Display','Off');
        u = fmincon(f,0.5,[],[],[],[],0,1,[],options);
        phi = -(1-lam).*log(u)/c+a*(1-u).^(1/(1+gam));
        %fprintf('u = %d, f(u) = %d\n', u,f(u))
    end
end