export function ago(timestamp: string | number): string {
  const d = Date.now() - new Date(timestamp).getTime();
  const m = Math.floor(d / 60000);
  if (m < 1) return 'now';
  if (m < 60) return `${m}m`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h`;
  return `${Math.floor(h / 24)}d`;
}

export interface ContentSegment {
  type: 'text' | 'tag' | 'mention';
  value: string;
}

export function parseContent(text: string): ContentSegment[] {
  const parts: ContentSegment[] = [];
  const regex = /(#\w+)|(@\w+)/g;
  let lastIndex = 0;
  let match: RegExpExecArray | null;
  while ((match = regex.exec(text)) !== null) {
    if (match.index > lastIndex) {
      parts.push({ type: 'text', value: text.slice(lastIndex, match.index) });
    }
    if (match[1]) parts.push({ type: 'tag', value: match[1] });
    else if (match[2]) parts.push({ type: 'mention', value: match[2] });
    lastIndex = regex.lastIndex;
  }
  if (lastIndex < text.length) {
    parts.push({ type: 'text', value: text.slice(lastIndex) });
  }
  return parts.length ? parts : [{ type: 'text', value: text }];
}
