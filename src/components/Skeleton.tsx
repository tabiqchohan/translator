export function CardSkeleton() {
  return (
    <div className="animate-pulse rounded-lg border border-zinc-200 bg-white p-4 dark:border-zinc-700 dark:bg-zinc-800">
      <div className="mb-2 h-3 w-20 rounded bg-zinc-200 dark:bg-zinc-700" />
      <div className="space-y-2">
        <div className="h-3 w-full rounded bg-zinc-100 dark:bg-zinc-700" />
        <div className="h-3 w-4/5 rounded bg-zinc-100 dark:bg-zinc-700" />
        <div className="h-3 w-3/5 rounded bg-zinc-100 dark:bg-zinc-700" />
      </div>
    </div>
  );
}

export function TranslateSkeleton() {
  return (
    <div className="flex flex-col gap-4">
      <div className="flex gap-2">
        <div className="h-10 flex-1 animate-pulse rounded-lg bg-zinc-200 dark:bg-zinc-700" />
        <div className="h-10 w-10 animate-pulse rounded-lg bg-zinc-200 dark:bg-zinc-700" />
        <div className="h-10 flex-1 animate-pulse rounded-lg bg-zinc-200 dark:bg-zinc-700" />
      </div>
      <CardSkeleton />
      <div className="h-11 animate-pulse rounded-lg bg-zinc-200 dark:bg-zinc-700" />
      <CardSkeleton />
    </div>
  );
}

export function ListSkeleton({ count = 3 }: { count?: number }) {
  return (
    <div className="flex flex-col gap-3">
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} className="animate-pulse rounded-lg border border-zinc-200 p-4 dark:border-zinc-700">
          <div className="mb-2 h-3 w-16 rounded bg-zinc-200 dark:bg-zinc-700" />
          <div className="mb-1 h-3 w-full rounded bg-zinc-100 dark:bg-zinc-700" />
          <div className="h-3 w-3/4 rounded bg-zinc-100 dark:bg-zinc-700" />
        </div>
      ))}
    </div>
  );
}
