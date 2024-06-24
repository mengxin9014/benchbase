/*
 * Copyright 2020 by OLTPBenchmark Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

package com.oltpbenchmark.benchmarks.chbenchmark;

import com.oltpbenchmark.api.Procedure.UserAbortException;
import com.oltpbenchmark.api.TransactionType;
import com.oltpbenchmark.api.Worker;
import com.oltpbenchmark.benchmarks.chbenchmark.queries.GenericQuery;
import com.oltpbenchmark.types.DatabaseType;
import com.oltpbenchmark.types.TransactionStatus;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

public class CHBenCHmarkWorker extends Worker<CHBenCHmark> {
    public CHBenCHmarkWorker(CHBenCHmark benchmarkModule, int id) throws SQLException {
        super(benchmarkModule, id);
        if (benchmarkModule.getWorkloadConfiguration().getDatabaseType() == DatabaseType.TIDB) {
            // set storage type if needed
            Statement stmt = conn.createStatement();
            stmt.execute("set @@global.tidb_txn_mode='optimistic'");
            stmt.execute("set @@global.tidb_skip_isolation_level_check=1");
            if (benchmarkModule.getWorkloadConfiguration().getDBStorageType().equalsIgnoreCase("tikv")) {
                stmt.execute("set tidb_isolation_read_engines=\"tikv\"");
            } else if (benchmarkModule.getWorkloadConfiguration().getDBStorageType().equalsIgnoreCase("tiflash")) {
                stmt.execute("set tidb_isolation_read_engines=\"tiflash\"");
            }
            stmt.close();
        }
    }

    @Override
    protected TransactionStatus executeWork(Connection conn, TransactionType nextTransaction) throws UserAbortException, SQLException {
        try {
            GenericQuery proc = (GenericQuery) this.getProcedure(nextTransaction.getProcedureClass());
            proc.run(conn);
        } catch (ClassCastException e) {
            throw new RuntimeException(e);
        }

        return (TransactionStatus.SUCCESS);

    }
}
