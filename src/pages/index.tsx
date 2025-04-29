import Head from 'next/head';
import dynamic from 'next/dynamic';

const CanvasWrapper = dynamic(() => import('../components/CanvasWrapper'), { ssr: false });

export default function Home() {
  return (
    <>
      <Head>
        <title>GLSL Visualization</title>
      </Head>
      <main style={{ height: '100vh', margin: 0, padding: 0, overflow: 'hidden' }}>
        <CanvasWrapper />
      </main>
    </>
  );
}