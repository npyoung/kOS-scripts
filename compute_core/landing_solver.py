#!/usr/bin/env python
import os
import json
import pyinotify
import numpy as np
from gfold import GFOLDSolver

state_fname = 'state.json'
trajectory_fname = 'trajectory.json'
sim_dt = 1.
spline_dt = 1./30

class INotifyHandler(pyinotify.ProcessEvent):
    def process_IN_CLOSE_WRITE(self, evt):
        print("State file '{}' modified".format(evt.pathname))
        with open(state_fname, 'r') as f:
            state = json.load(f)
        x, v, u, z, t = solve_trajectory(**state)
        save_trajectory(x, v, u, t)
        plot_trajectory(x, v, u, z, t)


def resample(x, dt_from, dt_to):
    from scipy.interpolate import interp1d

    t0 = np.arange(0, x.shape[0]) * dt_from
    t1 = np.arange(0, t0[-1]) * dt_to
    interpolator = interp1d(t0, x, kind=1, axis=0, assume_sorted=True)
    return t1, interpolator(t1)

def solve_trajectory(position, velocity, mdry, mwet, Isp, Tmax, g):
    ppts = GFOLDSolver(position, velocity, mdry, mwet, Isp, Tmax,
                       g, glide_slope=75, max_angle=15,
                       vert_time=5, dt=sim_dt)
    ppts.best_trajectory()

    _, x = resample(ppts.x.value, sim_dt, spline_dt)
    _, v = resample(ppts.v.value, sim_dt, spline_dt)
    _, u = resample(ppts.u.value, sim_dt, spline_dt)
    t, z = resample(ppts.z.value, sim_dt, spline_dt)

    return x, v, u, z, t

def save_trajectory(x, v, u, t):
    with open(trajectory_fname, 'w') as f:
        json.dump({'t': t.tolist(),
                   'x': x.tolist(),
                   'v': v.tolist(),
                   'u': u.tolist()},
                  f,
                  separators=(',', ':'),
                  indent=4)

def plot_trajectory(x, v, u, z, t):
    import matplotlib.pyplot as plt
    import seaborn as sns

    fig, ax = plt.subplots(6, 1, figsize=(8, 10))

    ax[0].plot(x[:,0], x[:,2])
    ax[0].plot(x[:,0], np.abs(x[:,0]) * np.tan((90 - 75) / 180 * np.pi), ls='--')
    ax[0].set_ylim(bottom=0)
    ax[0].legend(["Position", "Glide slope constraint"])
    ax[0].set_xlabel("Horizontal displacement")
    ax[0].set_ylabel("Altitude")

    ax[1].plot(t, np.arctan2(u[:,0], u[:,2]) * 180 / np.pi)
    ax[1].set_ylim([-90, 90])
    ax[1].legend(["Angle from vertical"])
    ax[1].set_ylabel("Angle (deg)")

    ax[2].plot(t, v)
    ax[2].legend([r"$v_x$", r"$v_y$", r"$v_z$"])

    ax[3].plot(t, u)
    ax[3].legend([r"$a_x$", r"$a_y$", r"$a_z$"])

    ax[4].plot(t, np.sqrt(np.sum(np.square(np.multiply(u, np.exp(z))),-1)), c='m')
    #ax[4].axhline(Tmax, color='c', ls='--')
    ax[4].set_ylim(bottom=0)
    ax[4].legend([r"$\|T\|$", r"$T_{max}$"])

    ax[5].plot(t, np.exp(z), c='m')
    #ax[5].set_ylim([mdry, mwet])
    ax[5].legend(["Mass"])
    ax[5].set_xlabel("Time (s)")

    plt.tight_layout()
    plt.show(block=False)

def main():
    watchman = pyinotify.WatchManager()
    notifier = pyinotify.Notifier(watchman, INotifyHandler())
    watchman.add_watch(state_fname, pyinotify.ALL_EVENTS)
    notifier.loop()


if __name__ == "__main__":
    main()
