-- Optional starter taxonomy. Apply after the initial migration.
-- No demo accounts, answer keys, or fabricated published lessons.
begin;
insert into public.categories(kind, slug, name, sort_order) values
  ('data_structure', 'linear-structures', 'Linear Structures', 1),
  ('data_structure', 'hashing', 'Hashing', 2),
  ('data_structure', 'trees', 'Trees', 3),
  ('data_structure', 'graphs', 'Graphs', 4),
  ('algorithm', 'sorting', 'Sorting Algorithms', 1),
  ('algorithm', 'searching', 'Searching Algorithms', 2),
  ('algorithm', 'graph-algorithms', 'Graph Algorithms', 3),
  ('algorithm', 'tree-traversal', 'Tree Traversal', 4),
  ('algorithm', 'recursion', 'Recursion', 5),
  ('algorithm', 'dynamic-programming', 'Dynamic Programming', 6),
  ('algorithm', 'greedy', 'Greedy Algorithms', 7)
on conflict (slug) do nothing;

insert into public.topics(category_id, slug, title, description, difficulty, sort_order)
select c.id, t.slug, t.title, t.description, t.difficulty::public.difficulty_level, t.sort_order
from (values
  ('linear-structures', 'arrays', 'Arrays', 'Indexed collections of elements.', 'beginner', 1),
  ('linear-structures', 'linked-lists', 'Linked Lists', 'Nodes linked by references.', 'beginner', 2),
  ('linear-structures', 'stacks', 'Stacks', 'Last-in, first-out collections.', 'beginner', 3),
  ('linear-structures', 'queues', 'Queues', 'First-in, first-out collections.', 'beginner', 4),
  ('hashing', 'hash-tables', 'Hash Tables', 'Key-value lookup with hashing.', 'intermediate', 1),
  ('trees', 'trees', 'Trees', 'Hierarchical collections of nodes.', 'intermediate', 1),
  ('trees', 'binary-search-trees', 'Binary Search Trees', 'Ordered binary trees.', 'intermediate', 2),
  ('trees', 'heaps', 'Heaps', 'Trees supporting priority access.', 'intermediate', 3),
  ('graphs', 'graphs', 'Graphs', 'Nodes connected by edges.', 'intermediate', 1),
  ('sorting', 'bubble-sort', 'Bubble Sort', 'Sort by swapping adjacent elements.', 'beginner', 1),
  ('sorting', 'merge-sort', 'Merge Sort', 'Divide, sort, and merge.', 'intermediate', 2),
  ('sorting', 'quick-sort', 'Quick Sort', 'Partition around a pivot.', 'intermediate', 3),
  ('searching', 'binary-search', 'Binary Search', 'Search a sorted collection by halving.', 'beginner', 1),
  ('graph-algorithms', 'breadth-first-search', 'Breadth-First Search', 'Explore nodes level by level.', 'intermediate', 1),
  ('graph-algorithms', 'depth-first-search', 'Depth-First Search', 'Explore paths before backtracking.', 'intermediate', 2),
  ('graph-algorithms', 'dijkstra', 'Dijkstra''s Algorithm', 'Find shortest paths with nonnegative edge weights.', 'advanced', 3)
) as t(category_slug, slug, title, description, difficulty, sort_order)
join public.categories c on c.slug = t.category_slug
on conflict (slug) do nothing;
commit;
