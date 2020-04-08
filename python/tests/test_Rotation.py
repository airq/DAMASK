import os

import pytest
import numpy as np

from damask import Rotation

n = 1000
atol=1.e-4
scatter=1.e-2

@pytest.fixture
def default():
    """A set of n random rotations."""
    specials = np.array(
              [np.array([ 1.0, 0.0, 0.0, 0.0]),
               #-----------------------------------------------
               np.array([0.0, 1.0, 0.0, 0.0]),
               np.array([0.0, 0.0, 1.0, 0.0]),
               np.array([0.0, 0.0, 0.0, 1.0]),
               np.array([0.0,-1.0, 0.0, 0.0]),
               np.array([0.0, 0.0,-1.0, 0.0]),
               np.array([0.0, 0.0, 0.0,-1.0]),
               #-----------------------------------------------
               np.array([1.0, 1.0, 0.0, 0.0])/np.sqrt(2.),
               np.array([1.0, 0.0, 1.0, 0.0])/np.sqrt(2.),
               np.array([1.0, 0.0, 0.0, 1.0])/np.sqrt(2.),
               np.array([0.0, 1.0, 1.0, 0.0])/np.sqrt(2.),
               np.array([0.0, 1.0, 0.0, 1.0])/np.sqrt(2.),
               np.array([0.0, 0.0, 1.0, 1.0])/np.sqrt(2.),
               #-----------------------------------------------
               np.array([1.0,-1.0, 0.0, 0.0])/np.sqrt(2.),
               np.array([1.0, 0.0,-1.0, 0.0])/np.sqrt(2.),
               np.array([1.0, 0.0, 0.0,-1.0])/np.sqrt(2.),
               np.array([0.0, 1.0,-1.0, 0.0])/np.sqrt(2.),
               np.array([0.0, 1.0, 0.0,-1.0])/np.sqrt(2.),
               np.array([0.0, 0.0, 1.0,-1.0])/np.sqrt(2.),
               #-----------------------------------------------
               np.array([0.0, 1.0,-1.0, 0.0])/np.sqrt(2.),
               np.array([0.0, 1.0, 0.0,-1.0])/np.sqrt(2.),
               np.array([0.0, 0.0, 1.0,-1.0])/np.sqrt(2.),
               #-----------------------------------------------
               np.array([0.0,-1.0,-1.0, 0.0])/np.sqrt(2.),
               np.array([0.0,-1.0, 0.0,-1.0])/np.sqrt(2.),
               np.array([0.0, 0.0,-1.0,-1.0])/np.sqrt(2.),
               #-----------------------------------------------
               np.array([1.0, 1.0, 1.0, 0.0])/np.sqrt(3.),
               np.array([1.0, 1.0, 0.0, 1.0])/np.sqrt(3.),
               np.array([1.0, 0.0, 1.0, 1.0])/np.sqrt(3.),
               np.array([1.0,-1.0, 1.0, 0.0])/np.sqrt(3.),
               np.array([1.0,-1.0, 0.0, 1.0])/np.sqrt(3.),
               np.array([1.0, 0.0,-1.0, 1.0])/np.sqrt(3.),
               np.array([1.0, 1.0,-1.0, 0.0])/np.sqrt(3.),
               np.array([1.0, 1.0, 0.0,-1.0])/np.sqrt(3.),
               np.array([1.0, 0.0, 1.0,-1.0])/np.sqrt(3.),
               np.array([1.0,-1.0,-1.0, 0.0])/np.sqrt(3.),
               np.array([1.0,-1.0, 0.0,-1.0])/np.sqrt(3.),
               np.array([1.0, 0.0,-1.0,-1.0])/np.sqrt(3.),
               #-----------------------------------------------
               np.array([0.0, 1.0, 1.0, 1.0])/np.sqrt(3.),
               np.array([0.0, 1.0,-1.0, 1.0])/np.sqrt(3.),
               np.array([0.0, 1.0, 1.0,-1.0])/np.sqrt(3.),
               np.array([0.0,-1.0, 1.0, 1.0])/np.sqrt(3.),
               np.array([0.0,-1.0,-1.0, 1.0])/np.sqrt(3.),
               np.array([0.0,-1.0, 1.0,-1.0])/np.sqrt(3.),
               np.array([0.0,-1.0,-1.0,-1.0])/np.sqrt(3.),
               #-----------------------------------------------
               np.array([1.0, 1.0, 1.0, 1.0])/2.,
               np.array([1.0,-1.0, 1.0, 1.0])/2.,
               np.array([1.0, 1.0,-1.0, 1.0])/2.,
               np.array([1.0, 1.0, 1.0,-1.0])/2.,
               np.array([1.0,-1.0,-1.0, 1.0])/2.,
               np.array([1.0,-1.0, 1.0,-1.0])/2.,
               np.array([1.0, 1.0,-1.0,-1.0])/2.,
               np.array([1.0,-1.0,-1.0,-1.0])/2.,
              ])
    specials += np.broadcast_to(np.random.rand(4)*scatter,specials.shape)
    specials /= np.linalg.norm(specials,axis=1).reshape(-1,1)
    specials[specials[:,0]<0]*=-1
    return [Rotation.fromQuaternion(s) for s in specials] + \
           [Rotation.fromRandom() for r in range(n-len(specials))]

@pytest.fixture
def reference_dir(reference_dir_base):
    """Directory containing reference results."""
    return os.path.join(reference_dir_base,'Rotation')


class TestRotation:

    def test_Eulers(self,default):
        for rot in default:
            m = rot.asQuaternion()
            o = Rotation.fromEulers(rot.asEulers()).asQuaternion()
            ok = np.allclose(m,o,atol=atol)
            if np.isclose(rot.asQuaternion()[0],0.0,atol=atol):
                ok = ok or np.allclose(m*-1.,o,atol=atol)
            print(m,o,rot.asQuaternion())
            assert ok

    def test_AxisAngle(self,default):
        for rot in default:
            m = rot.asEulers()
            o = Rotation.fromAxisAngle(rot.asAxisAngle()).asEulers()
            u = np.array([np.pi*2,np.pi,np.pi*2])
            ok = np.allclose(m,o,atol=atol)
            ok = ok or np.allclose(np.where(np.isclose(m,u),m-u,m),np.where(np.isclose(o,u),o-u,o),atol=atol)
            if np.isclose(m[1],0.0,atol=atol) or np.isclose(m[1],np.pi,atol=atol):
                sum_phi = np.unwrap([m[0]+m[2],o[0]+o[2]])
                ok = ok or np.isclose(sum_phi[0],sum_phi[1],atol=atol)
            print(m,o,rot.asQuaternion())
            assert ok

    def test_Matrix(self,default):
        for rot in default:
            m = rot.asAxisAngle()
            o = Rotation.fromAxisAngle(rot.asAxisAngle()).asAxisAngle()
            ok = np.allclose(m,o,atol=atol)
            if np.isclose(m[3],np.pi,atol=atol):
                ok = ok or np.allclose(m*np.array([-1.,-1.,-1.,1.]),o,atol=atol)
            print(m,o,rot.asQuaternion())
            assert ok

    def test_Rodriques(self,default):
        for rot in default:
            m = rot.asMatrix()
            o = Rotation.fromRodrigues(rot.asRodrigues()).asMatrix()
            print(m,o)
            assert np.allclose(m,o,atol=atol)

    def test_Homochoric(self,default):
        for rot in default:
            m = rot.asRodrigues()
            o = Rotation.fromHomochoric(rot.asHomochoric()).asRodrigues()
            ok = np.allclose(np.clip(m,None,1.e9),np.clip(o,None,1.e9),atol=atol)
            print(m,o,rot.asQuaternion())
            ok = ok or np.isclose(m[3],0.0,atol=atol)

    def test_Cubochoric(self,default):
        for rot in default:
            m = rot.asHomochoric()
            o = Rotation.fromCubochoric(rot.asCubochoric()).asHomochoric()
            print(m,o,rot.asQuaternion())
            assert np.allclose(m,o,atol=atol*1e2)

    def test_Quaternion(self,default):
        for rot in default:
            m = rot.asCubochoric()
            o = Rotation.fromQuaternion(rot.asQuaternion()).asCubochoric()
            print(m,o,rot.asQuaternion())
            assert np.allclose(m,o,atol=atol)
