import type { FleetConfig, SessionAuthority } from '../src/types.ts';

const root = '/Users/photon/projects/silicyte/silicyte-solo-dev';
const product = '/Users/photon/projects/silicyte/silicyte';

const OPUS = 'claude-opus-5';
const HAIKU = 'claude-haiku-4-5-20251001';

const everyWorkerIsYours: SessionAuthority = {
  mayOwnRoles: ['worker'],
  maxOwnedAtOnce: 6,
  maxTreeDepth: 1,
  verbs: ['read', 'send', 'interrupt', 'retune', 'kill', 'clear'],
};

const config: FleetConfig = {
  root,
  repos: [{ name: 'silicyte', absolutePath: product }],
  worktreesDir: `${root}/.silicyte/worktrees`,
  managerRole: 'root',
  maxSessions: 7,
  connectors: [],
  railsFrom: { remote: 'origin', branch: 'main' },
  stopFleetAtFiveHourPercent: 95,
  stopFleetAtWeeklyPercent: 100,

  roles: {
    root: {
      name: 'root',
      model: OPUS,
      effort: 'max',
      permissionMode: 'bypassPermissions',
      repos: [{ repo: 'silicyte', mode: 'own' }],
      connectors: ['trello', 'notion'],
      mayAskTheOperator: true,
      mayRestartTheFleet: true,
      maySeeAccountLimits: true,
      maySculptSkills: ['worker'],
      sessionAuthority: everyWorkerIsYours,
      maxPerRole: 1,
    },

    worker: {
      name: 'worker',
      model: HAIKU,
      effort: 'high',
      permissionMode: 'bypassPermissions',
      repos: [{ repo: 'silicyte', mode: 'own' }],
      grantsNoSessionAuthority: true,
      maxPerRole: 6,
    },
  },
};

export default config;
