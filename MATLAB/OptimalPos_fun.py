import dsp
import cvxpy as cp
import numpy as np
import matplotlib.pyplot as plt

def OptimalPos(
    p_pa2: np.ndarray,
    p_na2: np.ndarray,
    p_p2: np.ndarray,
    p_n2: np.ndarray,
    p_p4: np.ndarray,
    p_n4: np.ndarray,
    A_pa4: np.ndarray,
    A_na4: np.ndarray,
    A_p2: np.ndarray,
    A_n2: np.ndarray,
    A_p4: np.ndarray,
    A_n4: np.ndarray,
    a: np.ndarray,
    Phi: np.ndarray,
    N: float,
    K: float,
    C: float,
    theta: float = 0.25,
    alpha: float = 1.2,
    beta: float = 0.25,
    ):
    
    N = int(N)
    K = int(K)
    C = int(C)

    P = np.diag(p_p4+p_n4)
    
    M = np.transpose(M)

    y = cp.Variable(K)
    zp = cp.Variable(N)
    zn = cp.Variable(N)
    
    f = dsp.inner( zp-zn, P @ ( M @ y ) )
    f1 = (p_p2+p_n2) @ (M @ y)
    rho = p_pa2 @ cp.multiply(theta, cp.power(zp+zn,alpha))+p_na2 @ cp.multiply(theta,cp.power(zp+zn,alpha))
    
    constraints = [p @ z == 1, z >= 0]
    for i in range(N): #range(len(a)):
        constraints.append(p @ cp.maximum(z-a[i],0) <= Phi[i])

    obj = dsp.MinimizeMaximize(rho+f+f1)
    prob = dsp.SaddlePointProblem(obj, constraints)
    prob.solve()  # solves the problem

    print(prob.value)

    # fig = plt.figure()
    # axes = fig.add_axes([0.1, 0.1, 0.75, 0.75])
    # M = [-0.3,0.3]
    # axes.set_xlim(np.log(W)+M[0], np.log(W)+M[-1])
    # #axes.set_ylim(min(y.value), max(y.value))
    # #axes.plot(x,y.value-W*np.exp(x)
    # axes.plot(x,y.value)
    
    # plt.savefig('Pos.png')
    # plt.show()
        

    # # Constraint satisfied
    # print(q @ y.value)
    # zz = z.value
    # N = len(a)
    # const = []
    # for i in range(N): #range(len(a)):
    #     const.append(p @ np.maximum(zz-a[i],0))

    # const = np.array(const)
    # fig = plt.figure()
    # axes = fig.add_axes([0.1, 0.1, 0.75, 0.75])
    # axes.set_xlim(a[0], a[-1])
    # axes.set_ylim(min(const), max(Phi))
    # axes.plot(a,const)
    # axes.plot(a,Phi)
    # # axes.plot(a,dist.Psi(a))
    # plt.show()

    return y.value

z = OptimalPos(p, q, a, Phi, A, k, ky, theta, alpha, beta, N)
