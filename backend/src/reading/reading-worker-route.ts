import type { ReadingWorkerRoute } from './reading-task-scheduler.js';

export function workerRouteFor(operation: {
  readingType: string;
  coffeeCaptureContract?: string | null;
}): ReadingWorkerRoute {
  return operation.readingType === 'coffee' && operation.coffeeCaptureContract === 'three_view_v3'
    ? 'coffee-v3'
    : 'legacy';
}
