#!/usr/bin/env python3
import os
import json
import pyinotify
import numpy as np
from gfold import GFOLDSolver

state_fname = 'state.json'
trajectory_fname = 'trajectory.json'
sim_dt = 0.25
spline_dt = 1./10

class INotifyHandler(pyinotify.ProcessEvent):
    def process_IN_CLOSE_WRITE(self, evt):
        print("State file '{}' modified".format(state_fname))
        respond_to_state()


def respond_to_state():
    with open(state_fname, 'r') as f:
        raw = json.load(f)
    state = kos_to_numpy(raw)
    print("Solving with state:")
    print(state)
    x, v, u, z, t = solve_trajectory(**state)
    save_trajectory(x, v, u, t)
    plot_trajectory(x, v, u, z, t)

def kos_to_numpy(json_data):
    lex_items = json_data["entries"]
    out = {}
    for i in range(0, len(lex_items), 2):
        j = i + 1
        key = lex_items[i]
        val = lex_items[j]
        if isinstance(val, dict):
            val = np.array([val["x"], val["y"], val["z"]])
        out[key] = val
    return out

def resample(x, dt_from, dt_to):
    from scipy.interpolate import interp1d

    t0 = np.arange(0, x.shape[0]) * dt_from
    t1 = np.arange(0, t0[-1], dt_to)
    interpolator = interp1d(t0, x, kind=1, axis=0, assume_sorted=True)
    return t1, interpolator(t1)

def solve_trajectory(position, velocity, mdry, mwet, Isp, Tmax, g):
    ppts = GFOLDSolver(position, velocity, mdry, mwet, Isp, Tmax,
                       g, vmax=30, glide_slope=89, max_angle=15,
                       vert_time=5, dt=sim_dt)
    ppts.best_trajectory()

    _, x = resample(ppts.x.value, sim_dt, spline_dt)
    _, v = resample(ppts.v.value, sim_dt, spline_dt)
    _, u = resample(ppts.u.value, sim_dt, spline_dt)
    t, z = resample(ppts.z.value, sim_dt, spline_dt)

    return x, v, u, z, t

def np_to_vec(arr):
    if arr.ndim != 1 or len(arr) != 3:
        raise ValueError("array must be 1D with length 3 to be a kOS vector")
    out = {}
    out["x"], out["y"], out["z"] = arr.tolist()
    out["$type"] = "kOS.Suffixed.Vector"
    return out

def save_trajectory(x, v, u, t):
    out = {"items": [], "$type": "kOS.Safe.Encapsulation.ListValue"}
    N = len(t)
    for i in range(N):
        d = {"entries":[], "$type": "kOS.Safe.Encapsulation.Lexicon"}

        d["entries"].append("t")
        d["entries"].append(t[i])

        d["entries"].append("x")
        d["entries"].append(np_to_vec(x[i,:]))

        d["entries"].append("v")
        d["entries"].append(np_to_vec(v[i,:]))

        d["entries"].append("u")
        d["entries"].append(np_to_vec(u[i,:]))

        out["items"].append(d)

    with open(trajectory_fname, 'w') as f:
        json.dump(out, f, indent=4)

def dist(x, axis=-1):
    return np.sqrt(np.sum(np.square(x), axis))

def plot_trajectory(x, v, u, z, t):
    import matplotlib.pyplot as plt
    import seaborn as sns

    plt.ion()
    fig = plt.gcf()

    if len(fig.axes) == 0:
        fig, ax = plt.subplots(6, 1, figsize=(8, 10))
    else:
        ax = fig.axes
        for a in ax:
            a.clear()

    xlat = dist(x[:,:2])
    xvert = x[:,2]

    ulat = dist(u[:,:2])
    uvert = u[:,2]

    ax[0].plot(xlat, xvert)
    ax[0].plot(xlat, xlat * np.tan((90 - 89) / 180 * np.pi), ls='--')
    ax[0].invert_xaxis()
    ax[0].set_ylim(bottom=0)
    ax[0].legend(["Position", "Glide slope constraint"])
    ax[0].set_xlabel("Horizontal displacement")
    ax[0].set_ylabel("Altitude")

    ax[1].plot(t, 90 - np.arctan2(uvert, ulat) * 180 / np.pi)
    ax[1].set_ylim([-45, 45])
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
    plt.show()
    plt.pause(0.01)

def main():
    watchman = pyinotify.WatchManager()
    notifier = pyinotify.Notifier(watchman, INotifyHandler())
    watchman.add_watch(state_fname, pyinotify.ALL_EVENTS)
    notifier.loop()


if __name__ == "__main__":
    main()
