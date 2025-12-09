import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

import express, {Request, Response} from "express";
import cors from "cors";

admin.initializeApp();
const db = admin.firestore();

const app = express();
app.use(cors({origin: true}));
app.use(express.json());

/* ============================
   TIPAGENS
============================ */

interface MembroGrupo {
  nome: string;
  email: string;
}

interface Grupo {
  nome: string;
  descricao?: string;
  membros: MembroGrupo[];
  createdAt: FirebaseFirestore.Timestamp;
}

interface Transacao {
  descricao: string;
  valor: number;
  tipo: string;
  categoria: string;
  createdAt: FirebaseFirestore.Timestamp;

  // campos opcionais para grupos
  grupoId?: string;
  responsavelNome?: string;
  responsavelEmail?: string;
}

/* ============================
   ROTAS DE TRANSACOES
============================ */

// GET /transacoes?grupoId=xxx&responsavelEmail=yyy
app.get("/transacoes", async (req: Request, res: Response) => {
  try {
    const {grupoId, responsavelEmail} = req.query;

    let query: FirebaseFirestore.Query = db
      .collection("transacoes")
      .orderBy("createdAt", "desc");

    if (typeof grupoId === "string" && grupoId.trim() !== "") {
      query = query.where("grupoId", "==", grupoId.trim());
    }

    if (
      typeof responsavelEmail === "string" &&
      responsavelEmail.trim() !== ""
    ) {
      query = query.where(
        "responsavelEmail",
        "==",
        responsavelEmail.trim().toLowerCase(),
      );
    }

    const snapshot = await query.get();

    const lista = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...(doc.data() as Transacao),
    }));

    return res.status(200).json(lista);
  } catch (error) {
    console.error(error);
    return res.status(500).json({erro: "Erro ao buscar transações"});
  }
});

// POST /transacoes
app.post("/transacoes", async (req: Request, res: Response) => {
  try {
    const {
      descricao,
      valor,
      tipo,
      categoria,
      grupoId,
      responsavelNome,
      responsavelEmail,
    } = req.body as {
      descricao: string;
      valor: number;
      tipo: string;
      categoria: string;
      grupoId?: string;
      responsavelNome?: string;
      responsavelEmail?: string;
    };

    if (
      !descricao ||
      typeof descricao !== "string" ||
      typeof valor !== "number" ||
      !tipo ||
      !categoria
    ) {
      return res.status(400).json({
        erro: "Campos obrigatórios inválidos",
      });
    }

    const novaTransacao: Transacao = {
      descricao: descricao.trim(),
      valor,
      tipo,
      categoria,
      createdAt: admin.firestore.Timestamp.now(),
    };

    if (typeof grupoId === "string" && grupoId.trim() !== "") {
      novaTransacao.grupoId = grupoId.trim();
    }

    if (typeof responsavelNome === "string" && responsavelNome.trim() !== "") {
      novaTransacao.responsavelNome = responsavelNome.trim();
    }

    if (
      typeof responsavelEmail === "string" &&
      responsavelEmail.trim() !== ""
    ) {
      novaTransacao.responsavelEmail = responsavelEmail
        .trim()
        .toLowerCase();
    }

    const ref = await db.collection("transacoes").add(novaTransacao);

    return res.status(201).json({id: ref.id, ...novaTransacao});
  } catch (error) {
    console.error(error);
    return res.status(500).json({erro: "Erro ao criar transação"});
  }
});

// DELETE /transacoes/:id
app.delete("/transacoes/:id", async (req: Request, res: Response) => {
  try {
    const {id} = req.params;

    if (!id) {
      return res.status(400).json({erro: "ID da transação é obrigatório"});
    }

    await db.collection("transacoes").doc(id).delete();
    return res.status(204).send();
  } catch (error) {
    console.error(error);
    return res.status(500).json({erro: "Erro ao excluir transação"});
  }
});

/* ============================
   ROTAS DE GRUPOS
============================ */

// função utilitária para normalizar membros vindos do body
function normalizarMembros(
  membros?: Array<{ nome?: string; email?: string }>,
): MembroGrupo[] {
  if (!Array.isArray(membros)) return [];

  return membros.map((m) => {
    const nomeM =
      typeof m.nome === "string" ? m.nome.trim() : "";
    const emailM =
      typeof m.email === "string" ? m.email.trim().toLowerCase() : "";
    return {nome: nomeM, email: emailM};
  });
}

// POST /grupos (criar grupo)
app.post("/grupos", async (req: Request, res: Response) => {
  try {
    const {nome, descricao, membros} = req.body as {
      nome: string;
      descricao?: string;
      membros?: Array<{ nome?: string; email?: string }>;
    };

    if (!nome || typeof nome !== "string") {
      return res
        .status(400)
        .json({erro: "Nome do grupo é obrigatório."});
    }

    const listaMembros = normalizarMembros(membros);

    const novoGrupo: Grupo = {
      nome: nome.trim(),
      descricao: descricao?.trim(),
      membros: listaMembros,
      createdAt: admin.firestore.Timestamp.now(),
    };

    const ref = await db.collection("grupos").add(novoGrupo);

    return res.status(201).json({id: ref.id, ...novoGrupo});
  } catch (error) {
    console.error(error);
    return res.status(500).json({erro: "Erro ao criar grupo"});
  }
});

// GET /grupos (listar grupos)
app.get("/grupos", async (_req: Request, res: Response) => {
  try {
    const snapshot = await db
      .collection("grupos")
      .orderBy("createdAt", "desc")
      .get();

    const grupos = snapshot.docs.map((doc) => ({
      id: doc.id,
      ...(doc.data() as Grupo),
    }));

    return res.status(200).json(grupos);
  } catch (error) {
    console.error(error);
    return res.status(500).json({erro: "Erro ao listar grupos"});
  }
});

// GET /grupos/:id (detalhe do grupo)
app.get("/grupos/:id", async (req: Request, res: Response) => {
  try {
    const {id} = req.params;
    const doc = await db.collection("grupos").doc(id).get();

    if (!doc.exists) {
      return res.status(404).json({erro: "Grupo não encontrado"});
    }

    return res.status(200).json({id: doc.id, ...(doc.data() as Grupo)});
  } catch (error) {
    console.error(error);
    return res.status(500).json({erro: "Erro ao buscar grupo"});
  }
});

// PUT /grupos/:id (editar grupo)
app.put("/grupos/:id", async (req: Request, res: Response) => {
  try {
    const {id} = req.params;

    const docRef = db.collection("grupos").doc(id);
    const doc = await docRef.get();

    if (!doc.exists) {
      return res.status(404).json({erro: "Grupo não encontrado"});
    }

    const {nome, descricao, membros} = req.body as {
      nome?: string;
      descricao?: string;
      membros?: Array<{ nome?: string; email?: string }>;
    };

    const updateData: Partial<Grupo> = {};

    if (typeof nome === "string" && nome.trim() !== "") {
      updateData.nome = nome.trim();
    }

    if (typeof descricao === "string") {
      updateData.descricao = descricao.trim();
    }

    if (Array.isArray(membros)) {
      updateData.membros = normalizarMembros(membros);
    }

    await docRef.update(updateData);

    const atualizado = await docRef.get();

    return res.status(200).json({
      id: atualizado.id,
      ...(atualizado.data() as Grupo),
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({erro: "Erro ao atualizar grupo"});
  }
});

export const api = functions.https.onRequest(app);
