import { useState, useLayoutEffect } from 'react';

const useDevicePixelRatio = () => {
  const [dpr, setDpr] = useState<number>(typeof window !== 'undefined' ? window.devicePixelRatio : 1);

  useLayoutEffect(() => {
    const updateDpr = () => {
      setDpr(window.devicePixelRatio);
    };

    window.addEventListener('resize', updateDpr);
    window.matchMedia('(resolution: 1dppx)').addEventListener('change', updateDpr);

    return () => {
      window.removeEventListener('resize', updateDpr);
      window.matchMedia('(resolution: 1dppx)').removeEventListener('change', updateDpr);
    };
  }, []);

  return dpr;
};

export default useDevicePixelRatio;