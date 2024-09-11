clear
clc
%close all

%% Data

a=importdata('C:\Users\yoshi\OneDrive\Desktop\Research\OptimalDerivativePos\Maximin\spyccgmyy2sommats20231231output.mat');
days=unique(a(:,1));
ndays=length(days);
parm=abs(a(:,5:10));
cpv=parm(:,1);
cnv=parm(:,2);
bpv=1./parm(:,4);
bnv=1./parm(:,3);
ypv=2*exp(-abs(parm(:,5)));
ynv=2*exp(-abs(parm(:,6)));
parmm=[cpv bpv ypv cnv bnv ynv];

TT = length(a);

%% Path to OptimalPos_fun file

pythonpath = "MUF.py";

%% Constraints
C = 500;
lamp = linspace(1,2,C);
lamn = linspace(0.8,1,C);
a = 2;
b = 1;
c = 0.5;
gam = 0.75;
Phi_u = zeros(C,1);
for i=1:C
    Phi_u(i) = Phiup(a,c,gam,lamp(i));
end
Phi_l = Phitil(b,c,lamn);
eps = 0.05;

% Rebate
alpha = 1.2;

%% Discretization 

K = 40;   % discretization of y
N = 500; %discretization of z
X = [-1,1];
x = linspace(X(1),X(2),N);
delta = (X(2)-X(1))/N;
y = exp(x)-1;
x2 = x.*x;
x2inv = 1./x2;

xx = linspace(x(1),x(end),K);
I = eye(K);
MM = zeros(N,K);
for j=1:K
    ej = I(:,j);
    MM(:,j) = interp1(xx,ej,x,'spline','extrap');
end
y0 = MM\y';

%% Optimization
kappaN = 20;
kappamax = 1e2;
kappamin = -5e3;
kappa = linspace(kappamin,kappamax,kappaN);
res = zeros(size(kappa));

for tt = 1%1:TT/2
    % BCGMY
    params = [parmm(2*tt-1,:),parmm(2*tt,:)];
    
    cp = params(1);
    M = 1/params(2);
    yp = params(3);
    cn = params(4);
    G = 1/params(5);
    yn = params(6);
    
    xp = x(x>0);
    xn = x(x<0);
    
    eta = [0,0];
%     fun = @(eta)NA(cp,M,eta(1),yp,cn,G,eta(2),yn,xp,xn,x,delta);
%     eta = fminunc(fun,eta);
    
    M_eta = M+eta(1);
    G_eta = G+eta(2); %ensuring long stock and inverse stock cannot be scaled up indefinitely.
    
    pa2 = [(cn).*((-xn).^(2*alpha-yn-1)).*exp(G_eta*xn)*delta,...
           (cp).*(xp.^(2*alpha-yp-1)).*exp(-M_eta*xp)*delta];
    p2 = [(cn).*((-xn).^(2-yn-1)).*exp(G_eta*xn)*delta,...
          (cp).*(xp.^(2-yp-1)).*exp(-M_eta*xp)*delta];
    p4 = [(cn).*((-xn).^(4-yn-1)).*exp(G_eta*xn)*delta,...
          (cp).*(xp.^(4-yp-1)).*exp(-M_eta*xp)*delta];
    p0 = [(cn).*((-xn).^(-yn-1)).*exp(G_eta*xn).*(xn<-eps)*delta,...
          (cp).*(xp.^(-yp-1)).*exp(-M_eta*xp).*(xp>eps)*delta];
    
    % cost
    cpq = params(7);
    Mq = 1/params(8);
    ypq = params(9);
    cnq = params(10);
    Gq = 1/params(11);
    ynq = params(12);

    cpq = cp;
    Mq = M;
    ypq = yp;
    cnq = cn;
    Gq = G;
    ynq = yn;

    eta = [0,0];
%     fun = @(eta)NA(cpq,Mq,eta(1),ypq,cnq,Gq,eta(2),ynq,xp,xn,x,delta);
%     eta = fminunc(fun,eta);
    
    Mqt = Mq+eta(1);
    Gqt = Gq+eta(2);

    Mqt = M_eta;
    Gqt = G_eta;
    
    q0 = [(cnq).*((-xn).^(-ynq-1)).*exp(Gqt*xn)*delta,...
          (cpq).*(xp.^(-ypq-1)).*exp(-Mqt*xp)*delta]; %Estimated price to unwound the position in two weeks.
    for kk = 1:kappaN
        y = kappa(kk)*y0; 
    
        % load python.exe
        pyenv('Version',...
            'C:\Users\yoshi\OneDrive\Desktop\Research\OptimalDerivativePos\Maximin\maximin2\python.exe',...
            'ExecutionMode','OutOfProcess');
        py.importlib.import_module('numpy');
        
        pa2_py = py.numpy.array(pa2.');
        p2_py = py.numpy.array(p2.');
        p4_py = py.numpy.array(p4.');
        p0_py = py.numpy.array(p0.');
        q0_py = py.numpy.array(q0.');
        MM_py = py.numpy.array(MM.');
        lamp_py = py.numpy.array(lamp.');
        lamn_py = py.numpy.array(lamn.');
        Phi_u_py = py.numpy.array(Phi_u.');
        Phi_l_py = py.numpy.array(Phi_l.');
        y_py = py.numpy.array(y.');
        x2_py = py.numpy.array(x2.');
        x2inv_py = py.numpy.array(x2inv.');
        
        res(kk) = pyrunfile(pythonpath,"z",...
            pa2 = pa2_py,...
            p2 = p2_py,...
            p4 = p4_py,...
            p0 = p0_py,...
            q0 = q0_py,...
            MM = MM_py,...
            lamp = lamp_py,...
            lamn= lamn_py,...
            Phi_u = Phi_u_py,...
            Phi_l = Phi_l_py,...
            y = y_py,...
            x2 = x2_py,...
            x2inv = x2inv_py,...
            N = N,...
            K = K,...
            C = C,...
            alpha = alpha,...
            verbose ='False');
            %res = A*transpose(double(res));
    
    %     try
    %         res = pyrunfile("OptimalPos_fun.py","z",...
    %             pa2 = pa2_py,...
    %             p2 = p2_py,...
    %             p4 = p4_py,...
    %             p0 = p0_py,...
    %             q0 = q0_py,...
    %             MM = MM_py,...
    %             lamp = lamp_py,...
    %             lamn= lamn_py,...
    %             Phi_u = Phi_u_py,...
    %             Phi_l = Phi_l_py,...
    %             x = x_py,...
    %             x2 = x2_py,...
    %             x2inv = x2inv_py,...
    %             N = N,...
    %             K = K,...
    %             C = C,...
    %             alpha = alpha,...
    %             verbose = 'False');
    %             res = A*transpose(double(res));
    %     catch
    %         fprintf('For tt = %d, the solver CLARABEL failed\n', tt)
    %         res = zeros(size(N,1));
    %     end
        fprintf('kappa = %d, V = %d\n', kappa(kk), res(kk))
        fprintf('y = (%d,%d,%d,%d,%d,%d,%d,%d,%d,%d)\n\n',y(1),y(2),y(3),y(4),y(5),y(6),y(7),y(8),y(9),y(10))
    end

end

% 9734626800

%% Visualization

% Optimal delta
figure()
plot(kappa,res)
fpath=('C:\Users\yoshi\OneDrive\Desktop\Research\OptimalDerivativePos\Figures');
str=strcat('OptimalDelta_SPY','_',num2str(kappamin),'_',num2str(kappamax),'_',num2str(kappaN),'_',num2str(C));
fname=str;
saveas(gcf, fullfile(fpath, fname), 'epsc');

%% Routines

function phi = Phitil(b,c,lam)
    lamp = lam(lam<1);
    phi(lam<1) = -(1-lamp).*(log((1-lamp)/b)/c)-(b/c)*(1 - (1-lamp)/b );
    phi(lam==1) = -b/c;
    phi(lam==0) = (log(b)+1-b)/c;
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

function p = InverseContract(cp,M,yp,cn,G,yn,xp,xn,x,delta)
    nu = [cn*exp(G*xn).*(-xn).^(-1-yn),cp*exp(-M*xp).*xp.^(-1-yp)]*delta;
    p = nu*(exp(-x')-1);
end

function c = NA(cp,M,etap,yp,cn,G,etan,yn,xp,xn,x,delta)
    p = InverseContract(cp,M,yp,cn,G,yn,xp,xn,x,delta);
    M = M+etap;
    G = G+etan;
    nu = [cn*exp(G*xn).*(-xn).^(1-yn),cp*exp(-M*xp).*xp.^(1-yp)]*delta;    
    c = (nu*(exp(-x')-p)).^2+(nu*(exp(x')-1)).^2;
end