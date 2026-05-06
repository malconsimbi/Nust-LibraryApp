import { Router, Request, Response } from 'express';
import { supabase } from '../config/supabase';

const router = Router();

// Get featured/trending PDFs
router.get('/featured/list', async (_req: Request, res: Response) => {
  try {
    const { data, error } = await supabase
      .from('pdfs')
      .select('*, categories(name, icon)')
      .order('views', { ascending: false })
      .limit(10);
    if (error) return res.status(400).json({ error: error.message });
    return res.json(data);
  } catch {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Get all PDFs (with optional search, category filter)
router.get('/', async (req: Request, res: Response) => {
  const { search, category_id, sort = 'recent', page = '1', limit = '20' } = req.query;
  const pageNum = parseInt(page as string);
  const limitNum = parseInt(limit as string);
  const offset = (pageNum - 1) * limitNum;

  try {
    let sortField = 'created_at';
    let ascending = false;

    if (sort === 'popular') {
      sortField = 'downloads';
    } else if (sort === 'alphabetical') {
      sortField = 'title';
      ascending = true;
    }

    // Use left join via !inner hint — works even when category_id is null
    let query = supabase
      .from('pdfs')
      .select('id, title, description, category_id, file_url, file_size, author, year, tags, views, downloads, featured, created_at, categories(name, icon)', { count: 'exact' })
      .range(offset, offset + limitNum - 1)
      .order(sortField, { ascending });

    if (search) query = query.ilike('title', `%${search}%`);
    if (category_id) query = query.eq('category_id', category_id);

    const { data, error, count } = await query;
    if (error) {
      console.error('pdfs GET error:', error.message);
      return res.status(400).json({ error: error.message });
    }
    return res.json({ data: data ?? [], total: count ?? 0, page: pageNum, limit: limitNum });
  } catch (err: any) {
    console.error('pdfs GET crash:', err.message);
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Get single PDF by ID
router.get('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  try {
    const { data, error } = await supabase
      .from('pdfs')
      .select('*, categories(name, icon)')
      .eq('id', id)
      .single();
    if (error) return res.status(404).json({ error: 'PDF not found' });
    // Increment view count
    await supabase.from('pdfs').update({ views: (data.views || 0) + 1 }).eq('id', id);
    return res.json(data);
  } catch {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Upload PDF metadata
router.post('/', async (req: Request, res: Response) => {
  const { title, description, category_id, file_url, file_size, author, year, tags } = req.body;
  try {
    const { data, error } = await supabase.from('pdfs').insert([
      { title, description, category_id, file_url, file_size, author, year, tags, views: 0, downloads: 0 },
    ]).select().single();
    if (error) return res.status(400).json({ error: error.message });
    return res.status(201).json(data);
  } catch {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Update PDF
router.patch('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  const updates = req.body;
  try {
    const { data, error } = await supabase.from('pdfs').update(updates).eq('id', id).select().single();
    if (error) return res.status(400).json({ error: error.message });
    return res.json(data);
  } catch {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

// Delete PDF
router.delete('/:id', async (req: Request, res: Response) => {
  const { id } = req.params;
  try {
    const { error } = await supabase.from('pdfs').delete().eq('id', id);
    if (error) return res.status(400).json({ error: error.message });
    return res.status(204).send();
  } catch {
    return res.status(500).json({ error: 'Internal server error' });
  }
});

export default router;
