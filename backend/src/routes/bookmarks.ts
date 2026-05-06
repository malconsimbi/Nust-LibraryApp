import { Router, Request, Response } from 'express';
import { supabase } from '../config/supabase';

const router = Router();

// Get user bookmarks
router.get('/:user_id', async (req: Request, res: Response) => {
  const { user_id } = req.params;
  try {
    const { data, error } = await supabase
      .from('bookmarks')
      .select('*, pdfs(id, title, description, file_url, author, year, views, downloads, categories(name, icon))')
      .eq('user_id', user_id)
      .order('created_at', { ascending: false });

    if (error) {
      console.warn('Bookmarks fetch error:', error.message);
      return res.json([]); // Return empty instead of erroring
    }
    return res.json(data ?? []);
  } catch {
    return res.json([]);
  }
});

// Toggle bookmark (add if not exists, remove if exists)
router.post('/', async (req: Request, res: Response) => {
  const { user_id, pdf_id } = req.body;
  if (!user_id || !pdf_id) {
    return res.status(400).json({ error: 'user_id and pdf_id are required' });
  }

  try {
    // Check if bookmark already exists
    const { data: existing } = await supabase
      .from('bookmarks')
      .select('id')
      .eq('user_id', user_id)
      .eq('pdf_id', pdf_id)
      .single();

    if (existing) {
      // Remove it
      const { error } = await supabase
        .from('bookmarks')
        .delete()
        .eq('user_id', user_id)
        .eq('pdf_id', pdf_id);

      if (error) throw error;
      return res.json({ saved: false, message: 'Bookmark removed' });
    } else {
      // Add it
      const { data, error } = await supabase
        .from('bookmarks')
        .insert([{ user_id, pdf_id }])
        .select()
        .single();

      if (error) throw error;
      return res.status(201).json({ saved: true, message: 'Bookmark added', data });
    }
  } catch (err: any) {
    console.error('Bookmark toggle error:', err.message);
    return res.status(400).json({ error: err.message });
  }
});

// Check if a specific PDF is bookmarked
router.get('/:user_id/check/:pdf_id', async (req: Request, res: Response) => {
  const { user_id, pdf_id } = req.params;
  try {
    const { data } = await supabase
      .from('bookmarks')
      .select('id')
      .eq('user_id', user_id)
      .eq('pdf_id', pdf_id)
      .single();
    return res.json({ saved: !!data });
  } catch {
    return res.json({ saved: false });
  }
});

export default router;
