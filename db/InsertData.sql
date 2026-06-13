USE DeTodo3D;

INSERT INTO [dbo].[Category] ([Name], [Description])
VALUES 
    ('Llavero', 'Souvenir de recuerdo artesanal con diseño exclusivo y alta calidad.'),
    ('Imán', 'Recuerdo magnético decorativo para nevera, ideal para coleccionistas.');

INSERT INTO [dbo].[Product] ([Name], [Description], [CategoryID], [UnitPrice], [UnitCost], [Stock])
VALUES 
    ('PVZ Girasol', 'Llaero decorativo del popular juego Plants vs Zombies, personaje Girasol.', 
     (SELECT [CategoryID] FROM [Category] WHERE [Name] = 'Imán'), 5.00, 2.00, 30),
    
    ('PVZ Lanza guisantes', 'Imán coleccionable de Plants vs Zombies con diseño del lanza guisantes.', 
     (SELECT [CategoryID] FROM [Category] WHERE [Name] = 'Imán'), 5.00, 2.00, 40),
    
    ('Minecraft Pollo', 'Llavero oficial temático de Minecraft con forma de pollo pixelado.', 
     (SELECT [CategoryID] FROM [Category] WHERE [Name] = 'Llavero'), 5.00, 2.00, 50);