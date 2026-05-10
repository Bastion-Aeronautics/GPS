import matplotlib.pyplot as plt
from mpl_toolkits.mplot3d import Axes3D

trajectory = [
    (0, 0, 0),
    (1, 2, 3),
    (2, 3, 5),
    (4, 5, 7)

]

def plot_shit(trajectory):
    x = [p[0] for p in trajectory]
    y = [p[1] for p in trajectory]
    z = [p[2] for p in trajectory]


    fig = plt.figure()
    ax = fig.add_subplot(111, projection='3d')

    ax.plot(x, y, z)
    ax.set_xlabel('X')
    ax.set_ylabel('Y')
    ax.set_zlabel('Z')
    plt.savefig("graph.png")
    plt.show()

plot_shit(trajectory)