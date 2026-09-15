import { expect, it, vi } from 'vitest';
import { CloudTasksReadingTaskScheduler } from '../src/reading/reading-task-scheduler.js';
import { testConfig } from './helpers.js';

const config = testConfig({
  FIREBASE_PROJECT_ID: 'oracly-test',
  READING_TASK_QUEUE: 'reading-operations',
  READING_TASK_LOCATION: 'europe-west1',
  READING_TASK_TARGET_URL: 'https://candidate.example/internal/reading-tasks/process',
  READING_TASK_AUDIENCE: 'https://oracly-test.example',
  READING_TASK_SERVICE_ACCOUNT: 'runtime@oracly-test.iam.gserviceaccount.com',
});

it('schedules an operation-specific authenticated durable task', async () => {
  const request = vi.fn().mockResolvedValue({});
  const scheduler = new CloudTasksReadingTaskScheduler(config, { request });
  const operationId = '00000000000000000000000000000001';
  await scheduler.schedule({ operationId, atMs: 1_789_121_026_559, trigger: 'ready' });

  const call = request.mock.calls[0]![0];
  expect(call.data.task.name).toContain(`reading-${operationId}-ready`);
  expect(call.data.task.scheduleTime).toBe(new Date(1_789_121_026_559).toISOString());
  expect(call.data.task.httpRequest.oidcToken).toEqual({
    serviceAccountEmail: 'runtime@oracly-test.iam.gserviceaccount.com',
    audience: 'https://oracly-test.example',
  });
  expect(JSON.parse(Buffer.from(call.data.task.httpRequest.body, 'base64').toString())).toEqual({ operationId });
});

it('treats Cloud Tasks duplicate-name 409 as an idempotent success', async () => {
  const request = vi.fn().mockRejectedValue({ response: { status: 409 } });
  const scheduler = new CloudTasksReadingTaskScheduler(config, { request });
  await expect(scheduler.schedule({
    operationId: '00000000000000000000000000000002',
    atMs: 1_789_121_026_559,
    trigger: 'accelerated',
  })).resolves.toBeUndefined();
});
