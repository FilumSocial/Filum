<script lang="ts">
  import { auth } from '$lib/stores/auth.svelte';
  import { toast } from '$lib/stores/toast.svelte';

  let displayName = $state('');
  let bio = $state('');
  let saving = $state(false);
  let loaded = $state(false);

  $effect(() => {
    if (auth.profile && !loaded) {
      displayName = auth.profile.display_name;
      bio = auth.profile.bio || '';
      loaded = true;
    }
  });

  async function save() {
    if (!displayName.trim() || saving) return;
    saving = true;
    try {
      await auth.updateProfile({ display_name: displayName.trim(), bio: bio.trim() });
      toast.success('Profile updated');
    } catch (e) {
      toast.error('Failed to update profile');
    } finally {
      saving = false;
    }
  }
</script>

<svelte:head>
  <title>Filum - Settings</title>
</svelte:head>

<div>
  <div class="sticky-hd">
    <span class="font-semibold text-[15px]">Settings</span>
  </div>

  <div class="form">
    <label class="field">
      <span class="label">Display Name</span>
      <input class="input" type="text" bind:value={displayName} maxlength="50" disabled={saving} />
    </label>
    <label class="field">
      <span class="label">Bio</span>
      <textarea class="input textarea" bind:value={bio} maxlength="160" disabled={saving} rows="3"></textarea>
    </label>
    <div class="flex justify-end">
      <button class="save-btn" onclick={save} disabled={!displayName.trim() || saving}>
        {saving ? 'Saving...' : 'Save'}
      </button>
    </div>
  </div>
</div>

<style>
  .sticky-hd {
    display: flex;
    align-items: center;
    height: 48px;
    padding: 0 20px;
    position: sticky;
    top: 0;
    background: var(--bg-glass);
    backdrop-filter: blur(14px);
    z-index: 20;
    border-bottom: 1px solid var(--border);
  }
  .form {
    padding: 24px 20px;
    display: flex;
    flex-direction: column;
    gap: 20px;
  }
  .field {
    display: flex;
    flex-direction: column;
    gap: 6px;
  }
  .label {
    font-size: 12px;
    font-weight: 600;
    color: var(--text3);
    text-transform: uppercase;
    letter-spacing: 0.06em;
  }
  .input {
    background: var(--surface);
    border: 1px solid var(--border);
    border-radius: 8px;
    padding: 10px 12px;
    color: var(--text1);
    font-family: 'DM Sans', sans-serif;
    font-size: 14px;
    outline: none;
    transition: border-color 0.15s;
  }
  .input:focus {
    border-color: var(--accent);
  }
  .textarea {
    resize: none;
    line-height: 1.5;
  }
  .save-btn {
    padding: 8px 20px;
    border: none;
    border-radius: 8px;
    background: var(--accent);
    color: oklch(0.06 0 0);
    font-family: 'DM Sans', sans-serif;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    transition: opacity 0.15s;
  }
  .save-btn:hover {
    opacity: 0.87;
  }
  .save-btn:disabled {
    opacity: 0.35;
    cursor: default;
  }
</style>
