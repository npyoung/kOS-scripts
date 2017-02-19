import warnings
import numpy as np
from cvxpy import *

g0 = 9.81
eps = 1e-8

class GFOLDSolver:
    def __init__(self, x0, v0, mdry, mwet, Isp, Tmax, g,
                 vmax=None, glide_slope=None, max_angle=None, vert_time=None, dt=0.5):
        self.x0 = np.atleast_2d(x0)
        self.v0 = np.atleast_2d(v0)
        self.xf = np.zeros((1, 3))
        self.vf = np.zeros((1, 3))
        self.alpha = 1. / (g0 * Isp)
        self.Tmax = Tmax
        self.glide_slope = glide_slope
        self.dt = dt

        if mwet < mdry:
            raise ValueError("m_wet cannot be less than m_dry")
        else:
            self.mdry = mdry
            self.mwet = mwet

        if g > 0:
            warnings.warn("Gravity points up? Flipping sign of g")
            self.g = np.array([[0, 0, -g]])
        else:
            self.g = np.array([[0, 0, g]])

        if vmax is None or vmax > 0:
            self.vmax = vmax
        else:
            raise ValueError("Vmax cannot be <= 0")

        gs0 = 90 - np.arctan(np.abs(x0[2]) / np.sqrt(np.sum(x0[:2]**2))) * 180 / np.pi
        if glide_slope == None:
            self.glide_slope = glide_slope
        elif glide_slope < 15 or glide_slope > 90:
            raise ValueError("Glide slope must be between 15 and 90 degrees")
        elif glide_slope < gs0:
            warnings.warn("Initial position violates glide slope constraint ({:0.2f} < {:0.2f}). Correcting.".format(glide_slope, gs0))
            self.glide_slope = min(90, gs0 + 0.1)
        else:
            self.glide_slope = glide_slope

        if (vert_time is None or not vert_time > 0) and max_angle:
            warnings.warn("max_angle given, but vert_time not > 0")
            self.max_angle = None
            self.vert_time = None
        else:
            self.max_angle = max_angle
            self.vert_time = vert_time

    def _gz(self, x):
        return np.maximum(eps, x)

    def _z0(self, t):
        return np.log(self._gz(self.mwet - self.alpha * self.Tmax * t))

    def _emz0(self, t):
        return 1. / (self.mwet - self.alpha * self.Tmax * t)

    def setup_problem(self, N):
        u = Variable(rows=N, cols=3, name='dv')
        x = Variable(rows=N, cols=3, name='position')
        v = Variable(rows=N, cols=3, name='velocity')
        z = Variable(rows=N, name='log(mass)')
        dt = self.dt
        g = self.g
        alpha = self.alpha

        obj = Minimize(norm1(u))

        constraints = [
            x[0,:] == self.x0,
            v[0,:] == self.v0,
            z[0,:] == np.log(self.mwet),
            x[-1,:] == self.xf,
            v[-1,:] == self.vf,
            u[-1,:] == np.zeros((1, 3)),
            z[-1] >= np.log(self.mdry)
        ]

        for i in range(N-1):
            constraints += [v[i+1,:] == v[i,:] + dt * g + (dt/2)*(u[i,:] + u[i+1,:]),
                            x[i+1,:] == x[i,:] + (dt/2)*(v[i,:] + v[i+1,:]) + (dt**2/12)*(u[i+1,:] - u[i,:]),
                            z[i+1] <= z[i] - alpha*(dt)*(norm2(u[i,:])),
                            self._z0(i*dt) <= z[i],
                            z[i] <= np.log(self.mwet),
                            norm2(u[i,:]) <= self.Tmax * self._emz0(i*dt) * (1-(z[i]-self._z0(i*dt))),
                           ]
        if self.vmax:
            for i in range(N-1):
                constraints += [norm2(v[i,:]) <= self.vmax]

        if self.glide_slope:
            for i in range(N-1):
                constraints += [norm2(x[i,:2]) <= x[i,2] * np.tan(self.glide_slope / 180 * np.pi)]

        if self.vert_time and i >= N - self.vert_time / self.dt:
            for i in range(N-1):
                constraints += [norm2(u[i,:2]) <= u[i,2] * np.tan(self.max_angle / 180 * np.pi)]

        self.problem = Problem(obj, constraints)
        self.u = u
        self.x = x
        self.v = v
        self.z = z

    def best_trajectory(self, coarse_res=10, fine_res=2):
        t_min = self.mdry * np.linalg.norm(self.v0, 2) / self.Tmax
        N_min = int(t_min / self.dt) + 1

        forward_step = int(coarse_res / self.dt)
        backward_step = int(fine_res / self.dt)

        obj = np.inf
        N = N_min

        print("N_min = {}".format(N_min))

        print("Forward searching {} steps at a time".format(forward_step))
        while obj == np.inf:
            N += forward_step
            self.setup_problem(N)
            obj = self.problem.solve()

        print("Backward searching {} steps at a time".format(backward_step))
        while obj < np.inf:
            last_N = N
            N -= backward_step
            self.setup_problem(N)
            obj = self.problem.solve()

        print("Selecting N = {}".format(last_N))

        self.setup_problem(last_N)
        self.problem.solve()

    def plot(self, show=True):
        raise NotImplementedError()
