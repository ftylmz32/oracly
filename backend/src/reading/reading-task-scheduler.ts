import { GoogleAuth } from 'google-auth-library';
import type { AppConfig } from '../config.js';

export type ReadingTaskTrigger = 'ready' | 'accelerated' | 'retry';

export interface ReadingTaskScheduler {
  schedule(input: {
    operationId: string;
    atMs: number;
    trigger: ReadingTaskTrigger;
  }): Promise<void>;
}

export class ReadingTaskUnavailable extends Error {
  constructor() {
    super('reading_task_unavailable');
    this.name = 'ReadingTaskUnavailable';
  }
}

export class NoopReadingTaskScheduler implements ReadingTaskScheduler {
  async schedule(): Promise<void> {
    throw new ReadingTaskUnavailable();
  }
}

export class CloudTasksReadingTaskScheduler implements ReadingTaskScheduler {
  private readonly auth: Pick<GoogleAuth, 'request'>;

  constructor(
    private readonly config: AppConfig,
    auth?: Pick<GoogleAuth, 'request'>,
  ) {
    this.auth = auth ?? new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    });
  }

  async schedule(input: {
    operationId: string;
    atMs: number;
    trigger: ReadingTaskTrigger;
  }): Promise<void> {
    const project = this.config.firebaseProjectId;
    const queue = this.config.readingTaskQueue;
    const location = this.config.readingTaskLocation;
    const target = this.config.readingTaskTargetUrl;
    const audience = this.config.readingTaskAudience;
    const serviceAccount = this.config.readingTaskServiceAccount;
    if (!project || !queue || !target || !audience || !serviceAccount) {
      throw new ReadingTaskUnavailable();
    }
    const parent = `projects/${project}/locations/${location}/queues/${queue}`;
    const safeTrigger = input.trigger === 'retry' ? `retry-${input.atMs}` : input.trigger;
    const name = `${parent}/tasks/reading-${input.operationId}-${safeTrigger}`;
    try {
      await this.auth.request({
        url: `https://cloudtasks.googleapis.com/v2/${parent}/tasks`,
        method: 'POST',
        data: {
          task: {
            name,
            scheduleTime: new Date(input.atMs).toISOString(),
            httpRequest: {
              httpMethod: 'POST',
              url: target,
              headers: { 'Content-Type': 'application/json' },
              body: Buffer.from(JSON.stringify({ operationId: input.operationId })).toString('base64'),
              oidcToken: {
                serviceAccountEmail: serviceAccount,
                audience,
              },
            },
          },
        },
      });
    } catch (error) {
      const status = (error as { response?: { status?: number } }).response?.status;
      if (status === 409) return;
      throw new ReadingTaskUnavailable();
    }
  }
}

export function createReadingTaskScheduler(config: AppConfig): ReadingTaskScheduler {
  if (
    config.firebaseProjectId &&
    config.readingTaskQueue &&
    config.readingTaskTargetUrl &&
    config.readingTaskAudience &&
    config.readingTaskServiceAccount
  ) {
    return new CloudTasksReadingTaskScheduler(config);
  }
  return new NoopReadingTaskScheduler();
}
